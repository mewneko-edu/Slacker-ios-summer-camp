import SwiftUI

/// 統一的空狀態樣式。
///
/// 專案原本有兩種寫法並存：手寫的漫畫風（GroupListView、PersonalBattleReportView）
/// 與系統的 `ContentUnavailableView`（MyTasksView ×2、ApplicantBattleProfileView、
/// NotificationInboxView、GroupAdmissionViews）。後者使用系統語意灰，壓在 BombTheme
/// 的米色／黃色底上會顯得褪色且不合品牌，因此統一往漫畫風收斂，
/// 並把字級與無障礙處理集中在這裡。
struct BombEmptyState<Actions: View>: View {
    let systemImage: String
    let title: String
    var message: String?
    var verticalPadding: CGFloat = 48
    @ViewBuilder let actions: Actions

    /// 圖示跟著字級縮放，避免在大字級下圖示與文字比例失衡。
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 36

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .black))
                .accessibilityHidden(true)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .black))

            if let message {
                Text(message)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BombTheme.ink.opacity(0.65))
            }

            actions
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(BombTheme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, verticalPadding)
    }
}

extension BombEmptyState where Actions == EmptyView {
    init(
        systemImage: String,
        title: String,
        message: String? = nil,
        verticalPadding: CGFloat = 48
    ) {
        self.init(
            systemImage: systemImage,
            title: title,
            message: message,
            verticalPadding: verticalPadding,
            actions: { EmptyView() }
        )
    }
}
