//
//  ContentView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/02/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .login:
                        LoginView(path: $path)
                        
                    case .selectGym:
                        SelectGymView(path: $path)
                        
                    case .profileSetup:
                        ProfileSetupFlowView(
                            onFinish: {
                                path.append(AppRoute.selectGym)
                            }
                        )
                        
                    case .dashboard:
                        DashboardView() }
                }
        }
    }
}

