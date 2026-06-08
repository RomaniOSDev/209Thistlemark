import SwiftUI
import UIKit
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 14) {
                        statsCard
                        actionsCard
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("This action removes all saved ingredients, counters, and achievements.")
            }
        }
    }

    private var statsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitleRow(title: "Stats", subtitle: "Your real usage counters")
                HStack(spacing: 10) {
                    MetricCell(title: "Entries", value: "\(store.itemsCreated)", symbol: "tray.full.fill")
                    MetricCell(title: "Minutes", value: "\(store.totalMinutesUsed / 60)", symbol: "clock.fill")
                    MetricCell(title: "Streak", value: "\(store.streakDays)d", symbol: "flame.fill")
                }
            }
        }
    }

    private var actionsCard: some View {
        AppCard {
            VStack(spacing: 10) {
                Button {
                    FeedbackManager.tap()
                    rateApp()
                } label: {
                    SettingsActionCell(title: "Rate Us", icon: "star.fill", tint: Color("AppPrimary"))
                }
                .buttonStyle(.plain)

                Button {
                    FeedbackManager.tap()
                    openPrivacyPolicy()
                } label: {
                    SettingsActionCell(title: "Privacy", icon: "lock.doc", tint: Color("AppPrimary"))
                }
                .buttonStyle(.plain)

                Button {
                    FeedbackManager.tap()
                    openTerms()
                } label: {
                    SettingsActionCell(title: "Terms", icon: "doc.text.fill", tint: Color("AppPrimary"))
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    FeedbackManager.tap()
                    showingResetAlert = true
                } label: {
                    SettingsActionCell(
                        title: "Reset All Data",
                        icon: "trash.fill",
                        tint: Color.red,
                        destructive: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: ExternalLinks.privacyPolicy) {
            UIApplication.shared.open(url)
        }
    }

    private func openTerms() {
        if let url = URL(string: ExternalLinks.terms) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
