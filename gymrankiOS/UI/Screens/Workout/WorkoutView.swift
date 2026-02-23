import SwiftUI

struct WorkoutView: View {

    @EnvironmentObject private var session: SessionManager
    @State private var selectedRoutine: WorkoutRoutine? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()

                VStack(spacing: 14) {
                    WorkoutTopBar()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            QuickActionsGrid()
                            RecoveryCard()

                            MyRoutinesCard(onDetails: { routine in
                                selectedRoutine = routine
                            })
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }

                // ✅ Modal centrado (reusa RoutineDetailSheet)
                if let routine = selectedRoutine {
                    ZStack {
                        Color.black.opacity(0.55)
                            .ignoresSafeArea()
                            .onTapGesture { selectedRoutine = nil }

                        RoutineDetailSheet(
                            routine: routine,
                            onClose: { selectedRoutine = nil }
                        )
                        .frame(maxWidth: 380, maxHeight: 560)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.black.opacity(0.35))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 18)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.9), value: routine.id)
                }
            }
        }
    }
}

// MARK: - Top bar

private struct WorkoutTopBar: View {
    var body: some View {
        HStack {
            Text("Entrenar")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button {
                print("menu")
            } label: {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

// MARK: - Quick actions (Navigation)

private enum QuickActionDestination {
    case explore, coachAI, history, progress
}

private struct QuickActionItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let destination: QuickActionDestination
}

private struct QuickActionsGrid: View {

    private let items: [QuickActionItem] = [
        .init(title: "Explorar", icon: "magnifyingglass", destination: .explore),
        .init(title: "Coach IA", icon: "sparkles", destination: .coachAI),
        .init(title: "Historial", icon: "arrow.counterclockwise", destination: .history),
        .init(title: "Progreso", icon: "chart.bar.fill", destination: .progress)
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { item in
                NavigationLink {
                    destinationView(for: item.destination)
                } label: {
                    QuickActionCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for dest: QuickActionDestination) -> some View {
        switch dest {
        case .explore:
            ExploreView()
        case .coachAI:
            CoachAIView()
        case .history:
            WorkoutHistoryView()
        case .progress:
            ProgressView()
        }
    }
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

// MARK: - Recovery

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

// MARK: - My routines

private struct MyRoutinesCard: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = MyRoutinesViewModel()

    let onDetails: (WorkoutRoutine) -> Void

    private var uid: String { session.userId ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Mis entrenamientos (\(vm.routines.count))")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                NavigationLink {
                    CreateRoutineView()
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.appGreen))
                }
                .buttonStyle(.plain)
                .disabled(uid.isEmpty)
                .opacity(uid.isEmpty ? 0.5 : 1)
            }

            Group {
                if uid.isEmpty {
                    Text("Iniciá sesión para guardar entrenamientos.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                } else if vm.isLoading && vm.routines.isEmpty {
                    Text("Cargando...")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                } else if let err = vm.errorMessage {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Error: \(err)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))

                        Button {
                            Task { await vm.load(userId: uid) }
                        } label: {
                            Text("Reintentar")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .frame(height: 38)
                                .background(Capsule().fill(Color.appGreen.opacity(0.95)))
                        }
                        .buttonStyle(.plain)
                    }

                } else if vm.routines.isEmpty {
                    NavigationLink {
                        CreateRoutineView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("📝").font(.system(size: 22))
                            Text("Carga tu primer entrenamiento")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                } else {
                    VStack(spacing: 12) {
                        ForEach(vm.routines.prefix(3)) { routine in
                            RoutineRow(
                                routine: routine,
                                onDetails: { onDetails(routine) }
                            )
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .task(id: uid) {
            guard !uid.isEmpty else { return }
            await vm.load(userId: uid)
        }
    }
}

private struct RoutineRow: View {
    let routine: WorkoutRoutine
    let onDetails: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(routine.title)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                HStack(spacing: 10) {
                    Text("\(routine.exercises.count) ejercicios")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))

                    if let desc = routine.description,
                       !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("• \(desc)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Button(action: onDetails) {
                Text("Detalles")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

#Preview {
    WorkoutView()
        .environmentObject(SessionManager())
}
