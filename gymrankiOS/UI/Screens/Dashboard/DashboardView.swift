import SwiftUI

struct DashboardView: View {

    @State private var selectedTab: Tab = .home
    @State private var workoutRoute: WorkoutRoute? = nil

    private let sidePadding: CGFloat = 16

    enum Tab: String, CaseIterable, Identifiable {
        case feed, challenges, home, workout, ranking
        var id: String { rawValue }

        var title: String {
            switch self {
            case .feed: return "Feed"
            case .challenges: return "Desafíos"
            case .home: return "Home"
            case .workout: return "Workout"
            case .ranking: return "Ranking"
            }
        }

        var icon: String {
            switch self {
            case .feed: return "dot.radiowaves.left.and.right"
            case .challenges: return "list.bullet.rectangle"
            case .home: return "house.fill"
            case .workout: return "dumbbell.fill"
            case .ranking: return "chart.bar.fill"
            }
        }
    }

    enum WorkoutRoute: Hashable, Identifiable {
        case explore, coachAI, history, progress
        var id: String { String(describing: self) }
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                TabScaffold(selectedTab: $selectedTab) {
                    MainView(
                        onGoToWorkout: { selectedTab = .workout },
                        onGoToRanking: { selectedTab = .ranking }
                    )
                }

            case .workout:
                TabScaffold(selectedTab: $selectedTab) {
                    WorkoutView()
                }

            case .feed:
                TabScaffold(selectedTab: $selectedTab) {
                    FeedView(bottomInset: 96)
                }

            case .challenges:
                TabScaffold(selectedTab: $selectedTab) {
                    ChallengesView()
                }

            case .ranking:
                TabScaffold(selectedTab: $selectedTab) {
                    RankingView(bottomInset: 96)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
