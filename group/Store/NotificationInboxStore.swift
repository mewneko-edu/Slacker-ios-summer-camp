import Foundation
import Observation

/// One account-scoped source of truth for notification history and read state.
@MainActor @Observable
final class NotificationInboxStore {
    /// 收件匣的保存上限。
    ///
    /// 修改前 `items` 只會成長、不會縮減，整個陣列又在每次變動時重新編碼寫進
    /// `UserDefaults`（啟動時整份載入記憶體），長期使用下會持續惡化。
    private enum Limits {
        /// 列表硬上限，超過時從最舊的開始丟。
        static let maxItems = 200
        /// 已讀項目的保留天數；未讀不受此限，避免未讀數字無聲消失。
        static let readRetention: TimeInterval = 30 * 24 * 3600
        /// 墓碑上限。只存字串，可以放得比 `maxItems` 寬鬆很多。
        static let maxKnownIDs = 2000
    }

    private(set) var items: [InboxNotification] = []
    private(set) var accountID: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var knownIDs: Set<String> = []
    /// 與 `knownIDs` 同步維護，用來在超過上限時淘汰最舊的墓碑。
    @ObservationIgnored private var knownOrder: [String] = []

    var unreadCount: Int { items.lazy.filter { !$0.isRead }.count }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func changeAccount(to uid: String?) {
        guard uid != accountID else { return }
        accountID = uid
        items = []
        knownIDs = []
        knownOrder = []
        guard let key = storageKey, let data = defaults.data(forKey: key),
              let saved = try? JSONDecoder().decode([InboxNotification].self, from: data) else { return }
        items = saved
        // 墓碑與 items 分開保存是必要的：items 會被修剪或被使用者刪除，
        // 但來源（例如被戳數仍超過門檻的 poke-threshold）會重新產生同一個 ID。
        // 若把去重集合從 items 回推，被清掉的通知會以「未讀」身分復活。
        if let idKey = knownIDsKey, let idData = defaults.data(forKey: idKey),
           let savedIDs = try? JSONDecoder().decode([String].self, from: idData) {
            knownOrder = savedIDs
        } else {
            // 舊版沒有獨立保存墓碑，從既有項目回填一次。
            knownOrder = saved.map(\.id)
        }
        knownIDs = Set(knownOrder)
        // 載入時也修剪一次，否則既有的肥大收件匣要等下一則通知進來才會瘦身。
        if prune() { save() }
    }

    func receive(_ notifications: [InboxNotification], for uid: String) {
        guard uid == accountID else { return }
        let added = notifications.filter { knownIDs.insert($0.id).inserted }
        guard !added.isEmpty else { return }
        knownOrder.append(contentsOf: added.map(\.id))
        items.append(contentsOf: added)
        items.sort { $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt > $1.createdAt }
        prune()
        save()
    }

    /// 使用者主動刪除單一通知。ID 會留在墓碑裡，確保不會再被同步回來。
    func remove(id: String) {
        guard items.contains(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        save()
    }

    func setRead(id: String, isRead: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }),
              items[index].isRead != isRead else { return }
        items[index].isRead = isRead
        save()
    }

    func receiveApplications(_ requests: [GroupJoinRequest], incoming: Bool, uid: String) {
        guard uid == accountID else { return }
        // A final decision supersedes the applicant's old "pending" unread badge.
        let completed = Set(requests.filter { $0.status != .pending }.map(\.requestID))
        if !incoming {
            markRead(ids: Set(items.filter {
                $0.kind == .applicationPending && completed.contains($0.relatedID ?? "")
            }.map(\.id)))
        }
        receive(requests.map { .application($0, incoming: incoming) }, for: uid)
    }

    func reconcileAdmissionReviews(groupID: String, pendingIDs: Set<String>, uid: String) {
        guard uid == accountID else { return }
        markRead(ids: Set(items.filter {
            $0.kind == .admissionReview && $0.groupID == groupID
                && !pendingIDs.contains($0.relatedID ?? "")
        }.map(\.id)))
    }

    func receivePoke(count: Int, groupID: String, groupName: String, uid: String, at date: Date = .now) {
        guard count > 10 else { return }
        receive([InboxNotification(id: "poke-threshold.\(groupID)", kind: .pokeThreshold,
                                   groupID: groupID, groupName: groupName, createdAt: date)], for: uid)
    }

    func receiveReminders(_ reminders: [DeadlineReminder], groups: [Group], tasks: [ProjectTask],
                          uid: String, now: Date) {
        let events = reminders.filter { $0.fireDate <= now }.compactMap { reminder -> InboxNotification? in
            guard let group = groups.first(where: { $0.id == reminder.groupID }) else { return nil }
            let kind: InboxNotification.Kind = reminder.opensPeerReview
                ? (reminder.id.hasSuffix(".0") ? .reviewAvailable : .reviewReminder)
                : (reminder.taskID == nil ? .projectDeadline : .taskDeadline)
            let task = tasks.first { $0.id == reminder.taskID }
            return InboxNotification(
                id: "\(reminder.id).\(Int(reminder.fireDate.timeIntervalSince1970))",
                kind: kind, groupID: group.id.uuidString, groupName: group.name,
                subject: task?.title ?? group.name, relatedID: reminder.taskID?.uuidString,
                eventDate: task?.deadline ?? group.deadline, createdAt: reminder.fireDate
            )
        }
        receive(events, for: uid)
    }

    func markRead(id: String) { markRead(ids: [id]) }
    func markAllRead() { markRead(ids: Set(items.map(\.id))) }

    private func markRead(ids: Set<String>) {
        var changed = false
        for index in items.indices where ids.contains(items[index].id) && !items[index].isRead {
            items[index].isRead = true
            changed = true
        }
        if changed { save() }
    }

    /// `items` 已依 `createdAt` 由新到舊排序，因此「最舊」一律在尾端。
    /// - Returns: 是否真的移除了東西，供呼叫端決定要不要寫入。
    @discardableResult
    private func prune(now: Date = .now) -> Bool {
        let originalItemCount = items.count
        let originalIDCount = knownOrder.count

        let cutoff = now.addingTimeInterval(-Limits.readRetention)
        // 只淘汰過期的已讀項目：未讀若被無聲移除，鈴鐺數字會莫名其妙變少。
        items.removeAll { $0.isRead && $0.createdAt < cutoff }

        if items.count > Limits.maxItems {
            items.removeLast(items.count - Limits.maxItems)
        }

        if knownOrder.count > Limits.maxKnownIDs {
            let overflow = knownOrder.count - Limits.maxKnownIDs
            for id in knownOrder.prefix(overflow) { knownIDs.remove(id) }
            knownOrder.removeFirst(overflow)
        }

        return items.count != originalItemCount || knownOrder.count != originalIDCount
    }

    private var storageKey: String? { accountID.map { "notifications.inbox.\($0)" } }
    private var knownIDsKey: String? { accountID.map { "notifications.knownIDs.\($0)" } }

    private func save() {
        guard let key = storageKey, let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
        if let idKey = knownIDsKey, let idData = try? JSONEncoder().encode(knownOrder) {
            defaults.set(idData, forKey: idKey)
        }
    }
}
