import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionManager
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
    }
}
