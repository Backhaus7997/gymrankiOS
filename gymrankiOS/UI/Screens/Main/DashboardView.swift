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
        ZStack {
            AppBackground().ignoresSafeArea()

            if selectedTab == .ranking {
                ZStack {
                    RankingView(bottomInset: 96)

                    VStack {
                        Spacer()
                        BottomTabBar(selected: $selectedTab)
                            .padding(.horizontal, sidePadding)
                            .padding(.bottom, 14)
                    }
                }

            } else if selectedTab == .challenges {
                ZStack {
                    ChallengesView()

                    VStack {
                        Spacer()
                        BottomTabBar(selected: $selectedTab)
                            .padding(.horizontal, sidePadding)
                            .padding(.bottom, 14)
                    }
                }

            } else if selectedTab == .feed {
                ZStack {
                    FeedView(bottomInset: 96)

                    VStack {
                        Spacer()
                        BottomTabBar(selected: $selectedTab)
                            .padding(.horizontal, sidePadding)
                            .padding(.bottom, 14)
                    }
                }

            } else {
                VStack(spacing: 14) {

                    Group {
                        if selectedTab == .workout {
                            WorkoutTopBar()
                        } else {
                            TopBar()
                        }
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.top, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            switch selectedTab {
                            case .home:
                                HomeQuickActionsRow(
                                    onLoadWorkout: { selectedTab = .workout },
                                    onViewRanking: { selectedTab = .ranking }
                                )

                                WeeklyMusclesCard()
                                TrainingCalendarCard()
                                SetsPerMuscleCard()

                            case .workout:
                                QuickActionsGrid { actionTitle in
                                    switch actionTitle {
                                    case "Explorar": workoutRoute = .explore
                                    case "Coach IA": workoutRoute = .coachAI
                                    case "Historial": workoutRoute = .history
                                    case "Progreso": workoutRoute = .progress
                                    default: break
                                    }
                                }
                                RecoveryCard()
                                MyRoutinesCard()

                            default:
                                PlaceholderCard(title: selectedTab.title)
                            }
                        }
                        .padding(.horizontal, sidePadding)
                        .padding(.bottom, 24)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    BottomTabBar(selected: $selectedTab)
                        .padding(.horizontal, sidePadding)
                        .padding(.bottom, 14)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $workoutRoute) { route in
            switch route {
            case .explore: ExploreView()
            case .coachAI: CoachAIView()
            case .history: WorkoutHistoryView()
            case .progress: ProgressView()
            }
        }
    }
}

// MARK: - Top bars

private struct TopBar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Hola 👋")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button {
                    print("notifications")
                } label: {
                    Image(systemName: "bell")
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    print("profile")
                } label: {
                    Text("A")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Atleta")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}

private struct WorkoutTopBar: View {
    var body: some View {
        HStack {
            Text("Entrenar")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                print("workout menu")
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - ✅ Nuevo row superior Home

private struct HomeQuickActionsRow: View {
    let onLoadWorkout: () -> Void
    let onViewRanking: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            HomeQuickCard(
                title: "Cargar\nentreno",
                subtitle: "Registrá tu sesión",
                icon: "figure.strengthtraining.traditional",
                onTap: onLoadWorkout
            )

            HomeQuickCard(
                title: "Ver ranking",
                subtitle: "Tu posición y top",
                icon: "chart.line.uptrend.xyaxis",
                onTap: onViewRanking
            )
        }
        .padding(.top, 2)
    }
}

private struct HomeQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.appGreen.opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HOME Cards (tu contenido actual)

private struct WeeklyMusclesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Músculos entrenados esta semana")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Basado en entrenamientos cargados")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "gearshape")
                    .foregroundColor(.white.opacity(0.55))
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.45))
                .overlay(
                    Image(systemName: "figure.stand")
                        .font(.system(size: 90, weight: .regular))
                        .foregroundColor(Color.appGreen.opacity(0.22))
                )
                .frame(height: 185)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            
            Button {
                print("cargar primer entrenamiento")
            } label: {
                Text("Cargar primer entrenamiento")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.25))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appGreen.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func Pill(_ text: String, isActive: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(isActive ? .black : .white.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? Color.appGreen.opacity(0.95) : Color.black.opacity(0.35))
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct TrainingCalendarCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Calendario de entrenamientos")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text("Objetivo semanal: 0/8")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            HStack(spacing: 10) {
                DayPill("Lun", isActive: true)
                DayPill("Mar")
                DayPill("Mié")
                DayPill("Jue")
                DayPill("Vie")
                DayPill("Sáb")
                DayPill("Dom")
            }
            .padding(.top, 4)

        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func DayPill(_ text: String, isActive: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.9))
            .frame(width: 46, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? Color.white.opacity(0.10) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
    }
}

private struct SetsPerMuscleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets por músculo")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Esta semana")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "bell")
                    .foregroundColor(.white.opacity(0.55))
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.25))
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - WORKOUT UI (como la imagen)

private struct QuickActionsGrid: View {

    let onSelect: (String) -> Void

    private let items: [QuickActionItem] = [
        .init(title: "Explorar", icon: "magnifyingglass"),
        .init(title: "Coach IA", icon: "sparkles"),
        .init(title: "Historial", icon: "arrow.counterclockwise"),
        .init(title: "Progreso", icon: "chart.bar.fill")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { item in
                Button {
                    onSelect(item.title)
                } label: {
                    QuickActionCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct QuickActionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

private struct QuickActionCard: View {
    let item: QuickActionItem

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appGreen.opacity(0.18))
                    .frame(width: 42, height: 42)

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }

            Text(item.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Spacer()
        }
        .padding(14)
        .frame(height: 78)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct RecoveryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Recuperación muscular")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Button("Detalles") { print("detalles") }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appGreen)
                    .buttonStyle(.plain)
            }

            HStack(spacing: 14) {
                RecoverySmallCard(title: "Abductores", percent: "100%")
                RecoverySmallCard(title: "Abdominales", percent: "100%")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appGreen.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct RecoverySmallCard: View {
    let title: String
    let percent: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💪")
                .font(.system(size: 28))

            Spacer()

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(percent)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

private struct MyRoutinesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Mis rutinas (0/1)")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Button {
                    print("add routine")
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.appGreen.opacity(0.95)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                Text("📝")
                    .font(.system(size: 30))

                Text("Creá tu primera rutina")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Placeholder

private struct PlaceholderCard: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text("Pantalla en construcción")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .frame(height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Bottom Tab Bar

private struct BottomTabBar: View {
    @Binding var selected: DashboardView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DashboardView.Tab.allCases) { tab in
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: tab == selected ? 18 : 17, weight: .semibold))
                            .foregroundColor(tab == selected ? Color.appGreen : .white.opacity(0.45))

                        Text(tab.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(tab == selected ? .white.opacity(0.90) : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.70))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
