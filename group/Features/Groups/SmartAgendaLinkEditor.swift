import SwiftUI

struct SmartAgendaLinkDraft: Identifiable {
    let id: String
    let link: SmartAgenda.MeetingLink?

    init(entry: SmartAgenda.LinkEntry? = nil) {
        id = entry?.id ?? UUID().uuidString.lowercased()
        link = entry?.link
    }
}

struct SmartAgendaLinkEditor: View {
    let store: SmartAgendaStore
    let draft: SmartAgendaLinkDraft
    let onDismiss: () -> Void
    @State private var title: String
    @State private var url: String
    @State private var error: String?
    @State private var confirmsDeletion = false

    init(store: SmartAgendaStore, draft: SmartAgendaLinkDraft, onDismiss: @escaping () -> Void) {
        self.store = store
        self.draft = draft
        self.onDismiss = onDismiss
        _title = State(initialValue: draft.link?.title ?? "")
        _url = State(initialValue: draft.link?.url ?? "")
    }

    private var canSave: Bool {
        !store.isSaving && title.count <= 120 && SmartAgenda.MeetingLink.validURL(url) != nil
    }

    var body: some View {
        ZStack {
            BombTheme.ink.opacity(0.48)
                .ignoresSafeArea()
                .onTapGesture { if !store.isSaving { onDismiss() } }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label(L10n.text(draft.link == nil ? "新增會議連結" : "編輯會議連結"), systemImage: "link")
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        BombCloseButton(action: onDismiss)
                    }
                    fields
                    actionButton(L10n.text(store.isSaving ? "儲存中…" : "儲存"),
                                 icon: "checkmark", highlighted: true) { save() }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.45)
                    actionButton(L10n.text("取消"), icon: "xmark", action: onDismiss)
                }
                .disabled(store.isSaving)
                .foregroundStyle(BombTheme.ink)
                .tint(BombTheme.ink)
                .padding(20)
                .background(BombTheme.paper, in: RoundedRectangle(cornerRadius: BombRadius.card))
                .overlay(RoundedRectangle(cornerRadius: BombRadius.card).stroke(BombTheme.ink, lineWidth: 3))
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.center)
        }
        .bombDialog(L10n.text("刪除連結？"), isPresented: $confirmsDeletion) {
            Button(L10n.text("取消"), role: .cancel) {}
            Button(L10n.text("刪除連結"), role: .destructive) { save(removing: true) }
        }
    }

    private var fields: some View {
        SwiftUI.Group {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("連結名稱（選填）"))
                    .font(.subheadline.weight(.bold))
                TextField(L10n.text("連結名稱"), text: $title)
                    .bombFormField()
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("網址"))
                    .font(.subheadline.weight(.bold))
                TextField("https://", text: $url)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .bombFormField()
            }
            if draft.link != nil {
                Button(role: .destructive) { confirmsDeletion = true } label: {
                    Label(L10n.text("刪除連結"), systemImage: "trash")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(BombTheme.red)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let error { Text(L10n.text(error)).foregroundStyle(BombTheme.red) }
        }
    }

    private func actionButton(_ title: String, icon: String, highlighted: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(highlighted ? BombTheme.ink : .white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(highlighted ? BombTheme.yellow : BombTheme.ink, in: RoundedRectangle(cornerRadius: BombRadius.control))
                .contentShape(RoundedRectangle(cornerRadius: BombRadius.control))
        }
        .buttonStyle(.plain)
    }

    private func save(removing: Bool = false) {
        Task {
            do {
                try await store.saveLink(id: draft.id, title: removing ? "" : title,
                                         url: removing ? "" : url, revision: draft.link?.revision)
                onDismiss()
            } catch { self.error = error.localizedDescription }
        }
    }
}
