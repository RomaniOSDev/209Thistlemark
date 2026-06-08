import SwiftUI

struct AppDepthCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let elevated: Bool

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        Color("AppSurface").opacity(0.98),
                        Color("AppBackground").opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color("AppTextSecondary").opacity(0.14), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(elevated ? 0.24 : 0.14),
                radius: elevated ? 8 : 4,
                x: 0,
                y: elevated ? 6 : 3
            )
    }
}

extension View {
    func appDepthCard(cornerRadius: CGFloat = 16, elevated: Bool = false) -> some View {
        modifier(AppDepthCardModifier(cornerRadius: cornerRadius, elevated: elevated))
    }
}
