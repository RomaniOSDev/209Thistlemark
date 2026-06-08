import SwiftUI

struct SuccessCheckmarkOverlay: View {
    let isVisible: Bool

    var body: some View {
        Group {
            if isVisible {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color("AppAccent"))
                    .padding(18)
                    .background(Color("AppSurface").opacity(0.96), in: Circle())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
    }
}

struct AchievementBannerView: View {
    let text: String?

    var body: some View {
        Group {
            if let text {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "rosette")
                            .foregroundStyle(Color("AppAccent"))
                        Text(text)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(Color("AppSurface"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: text)
            }
        }
    }
}
