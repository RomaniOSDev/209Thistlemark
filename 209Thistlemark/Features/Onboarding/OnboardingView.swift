import SwiftUI
import Combine

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var pageIndex = 0

    private let pages: [(headline: String, message: String, artwork: String)] = [
        (
            "Explore Ingredients",
            "Discover how the app helps you learn about various cooking ingredients.",
            "CalmHero"
        ),
        (
            "Tap for Details",
            "Simply tap an ingredient to see its description, uses, and culinary tips.",
            "CalmDashboard"
        ),
        (
            "Start Exploring",
            "Begin by searching for an ingredient you're curious about.",
            "CalmInsights"
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 16) {
                topBar
                    .padding(.horizontal, 16)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            page: page,
                            index: index,
                            total: pages.count
                        )
                        .tag(index)
                        .padding(.horizontal, 16)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: pageIndex)

                pageIndicators

                bottomAction
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Step \(pageIndex + 1) of \(pages.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .appDepthCard(cornerRadius: 12, elevated: false)
            Spacer()
            if pageIndex < pages.count - 1 {
                Button("Skip") {
                    FeedbackManager.tap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        pageIndex = pages.count - 1
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(
                        index == pageIndex
                            ? LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(colors: [Color("AppTextSecondary").opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: index == pageIndex ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: pageIndex)
            }
        }
    }

    private var bottomAction: some View {
        Button(action: handlePrimaryAction) {
            HStack(spacing: 8) {
                Text(pageIndex == pages.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Image(systemName: pageIndex == pages.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                    .font(.headline)
            }
            .foregroundStyle(Color("AppTextPrimary"))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 5)
        }
    }

    private func handlePrimaryAction() {
        FeedbackManager.tap()
        if pageIndex < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                pageIndex += 1
            }
        } else {
            FeedbackManager.complete()
            onFinish()
        }
    }
}

private struct OnboardingPageView: View {
    let page: (headline: String, message: String, artwork: String)
    let index: Int
    let total: Int
    @State private var show = false

    var body: some View {
        AppCard {
            VStack(spacing: 18) {
                AppArtworkView(name: page.artwork, height: 220)
                    .scaleEffect(show ? 1 : 0.92)
                    .opacity(show ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: show)

                VStack(spacing: 10) {
                    Text(page.headline)
                        .font(.title2.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                        .multilineTextAlignment(.center)

                    Text(page.message)
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color("AppAccent"))
                    Text("Page \(index + 1) / \(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .onAppear { show = true }
    }
}
