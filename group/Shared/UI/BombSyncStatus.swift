import SwiftUI

/// 同步失敗時的提示與重試入口。
///
/// 原本 GroupListView 有帶重試按鈕的版本，通知頁卻只有一行紅字叫使用者自己下拉，
/// 同樣情境兩種處理方式。抽成共用元件統一語彙。
struct BombSyncStatus: View {
    let message: String
    var isRetrying = false
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Label(message, systemImage: "icloud.slash")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)

            Button(isRetrying ? L10n.text("重試中…") : L10n.text("重試"), action: onRetry)
                .font(.subheadline.bold())
                .disabled(isRetrying)
        }
        .foregroundStyle(BombTheme.ink)
        .frame(maxWidth: .infinity)
    }
}
