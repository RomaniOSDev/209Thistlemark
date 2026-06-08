//
//  ContentView.swift
//  209Thistlemark
//
//  Created by Roman on 6/6/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var store = AppDataStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var isTimerActive = true

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                RootTabView()
            } else {
                OnboardingView {
                    store.hasSeenOnboarding = true
                    store.completeSession()
                }
            }
        }
        .environmentObject(store)
        .onReceive(minuteTimer) { _ in
            guard scenePhase == .active, isTimerActive else { return }
            store.addUsageTime(seconds: 60)
        }
        .onChange(of: scenePhase) { _, newValue in
            isTimerActive = newValue == .active
            if newValue == .active {
                store.completeSession()
            }
        }
    }
}

#Preview {
    ContentView()
}
