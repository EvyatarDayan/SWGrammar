//
//  SWGrammarApp.swift
//  SWGrammar
//
//  Created by EVYATAR DAYAN on 2026-01-19.
//

import SwiftUI

@main
struct SWGrammarApp: App {
    @State private var showMainView = false
    @State private var showWelcome = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
    var body: some Scene {
        WindowGroup {
            if showMainView {
                MainView()
                    .sheet(isPresented: $showWelcome) {
                        WelcomeView(isPresented: $showWelcome)
                    }
                    .onAppear {
                        // Show welcome if user hasn't seen it
                        if !hasSeenWelcome {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showWelcome = true
                            }
                        }
                    }
            } else {
                LogoView {
                    withAnimation {
                        showMainView = true
                    }
                }
            }
        }
    }
}
