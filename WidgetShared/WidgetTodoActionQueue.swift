import Foundation

/// A tick the user made on the widget that the app still has to push to the backend.
///
/// The widget extension cannot talk to Firebase, so completing a subtask from the Home
/// Screen is recorded here and replayed by the app the next time it becomes active.
struct WidgetTodoAction: Codable, Equatable {
    let subtaskID: UUID
    let taskID: UUID
    let requestedAt: Date

    /// Pending ticks are hidden from the widget. Give up after a while so a tick that can
    /// never be replayed (task deleted while offline, say) stops hiding a real to-do.
    static let expiry: TimeInterval = 15 * 60

    func isStale(at date: Date = .now) -> Bool {
        date.timeIntervalSince(requestedAt) > Self.expiry
    }
}

/// Pending widget ticks, stored in the App Group so both processes see the same queue.
enum WidgetTodoActionQueue {
    static func pending() -> [WidgetTodoAction] {
        guard let data = WidgetSharedConfig.defaults?.data(forKey: WidgetSharedConfig.todoActionQueueKey),
              let actions = try? JSONDecoder().decode([WidgetTodoAction].self, from: data) else { return [] }
        return actions
    }

    /// Subtasks the app should treat as already completed, so a republished snapshot does not
    /// resurrect a row the user already ticked off on the Home Screen.
    static func pendingSubtaskIDs(at date: Date = .now) -> Set<UUID> {
        Set(pending().filter { !$0.isStale(at: date) }.map(\.subtaskID))
    }

    /// Called from the widget. Re-ticking the same subtask keeps the original timestamp so a
    /// repeated tap cannot extend the window in which the row stays hidden.
    static func enqueue(_ action: WidgetTodoAction) {
        var actions = pending()
        guard !actions.contains(where: { $0.subtaskID == action.subtaskID }) else { return }
        actions.append(action)
        write(actions)
    }

    static func remove(subtaskIDs: Set<UUID>) {
        guard !subtaskIDs.isEmpty else { return }
        let remaining = pending().filter { !subtaskIDs.contains($0.subtaskID) }
        write(remaining)
    }

    private static func write(_ actions: [WidgetTodoAction]) {
        guard let defaults = WidgetSharedConfig.defaults else { return }
        if actions.isEmpty {
            defaults.removeObject(forKey: WidgetSharedConfig.todoActionQueueKey)
        } else if let data = try? JSONEncoder().encode(actions) {
            defaults.set(data, forKey: WidgetSharedConfig.todoActionQueueKey)
        }
    }
}
