import SwiftUI
import Foundation

struct ContentView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if session.isLoggedIn {
                    DashboardView()
                } else {
                    HomeView(path: $path)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .login:
                    LoginView(path: $path)

                case .selectGym:
                    SelectGymView(path: $path)

                case .profileSetup:
                    ProfileSetupFlowView(onFinish: {
                        path.append(AppRoute.selectGym)
                    })

                case .dashboard:
                    DashboardView()
                }
            }
        }
        .task {
            await session.refreshPeriodIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            Task { await session.refreshPeriodIfNeeded() }
        }
    }
}
