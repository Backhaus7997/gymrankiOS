import SwiftUI

struct WorkoutView: View {

    @EnvironmentObject private var session: SessionManager

    // ✅ Rutinas (plantillas) para "Mis entrenamientos"
    @StateObject private var routinesVM = MyRoutinesViewModel()

    // ✅ Plan semanal (MainView / UserDefaults) para RECUPERACIÓN
    @State private var routinePlan: RoutinePlan = RoutineStorage.load() ?? RoutinePlan()

    // Modal de detalles de rutina (el que ya tenías)
    @State private var selectedRoutine: WorkoutRoutine? = nil

    private var uid: String { session.userId ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()

                VStack(spacing: 14) {
                    WorkoutTopBar()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            QuickActionsGrid()

                            // ✅ Recuperación basada en el PLAN semanal (Mi rutina)
                            RecoveryCard(plan: routinePlan)

                            // ✅ Mis entrenamientos (routines de Firebase)
                            MyRoutinesCard(
                                vm: routinesVM,
                                uid: uid,
                                onDetails: { routine in
                                    selectedRoutine = routine
                                }
                            )
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
            .task(id: uid) {
                guard !uid.isEmpty else { return }
                await routinesVM.load(userId: uid)
            }
            // ✅ Cada vez que entrás a Workout, refresca el plan desde UserDefaults
            .onAppear {
                routinePlan = RoutineStorage.load() ?? RoutinePlan()
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

// MARK: - Recovery (basado en el plan semanal - Mi rutina)

private struct RecoveryCard: View {

    let plan: RoutinePlan
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Recuperación muscular")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Button("Detalles") { showDetails = true }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.appGreen)
                    .buttonStyle(.plain)
                    .disabled(plan.isEmpty)
                    .opacity(plan.isEmpty ? 0.5 : 1)
            }

            if plan.isEmpty {
                Text("Cargá tu plan en “Mi rutina” para ver la recuperación.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.top, 2)

            } else {
                let schedule = plan.recoverySchedule()
                let top = MuscleRecoveryEngine.top(schedule: schedule, limit: 2)

                if top.isEmpty {
                    Text("Asigná músculos por día en tu plan para ver la recuperación.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                        .padding(.top, 2)
                } else {
                    HStack(spacing: 14) {
                        ForEach(top) { item in
                            RecoverySmallCard(title: item.muscle, percent: item.percent)
                        }

                        if top.count == 1 {
                            Spacer().frame(maxWidth: .infinity)
                        }
                    }
                }
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
        .sheet(isPresented: $showDetails) {
            MuscleRecoveryDetailsView(schedule: plan.recoverySchedule())
                .presentationDetents([.large])
        }
    }
}

private struct RecoverySmallCard: View {
    let title: String
    let percent: Double // 0...1

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appGreen.opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName(for: title))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appGreen.opacity(0.95))
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .center) // controla layout
            .padding(.top, 2)

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.80)

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))

                    Capsule()
                        .fill(Color.appGreen.opacity(0.90))
                        .frame(width: max(8, w * CGFloat(min(max(percent, 0), 1))))
                }
            }
            .frame(height: 10)

            Text("\(Int(round(percent * 100)))%")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 150) // mantenemos tu altura
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func iconName(for muscle: String) -> String {
        switch muscle.lowercased() {
        case "pecho": return "heart.fill"
        case "espalda": return "figure.strengthtraining.traditional"
        case "hombros": return "figure.arms.open"
        case "bíceps", "biceps": return "bolt.fill"
        case "tríceps", "triceps": return "bolt.circle.fill"
        case "abdomen", "abdominales": return "circle.grid.cross.fill"
        case "glúteos", "gluteos": return "figure.walk"
        case "cuadriceps": return "figure.run"
        case "femorales": return "figure.run.circle.fill"
        case "pantorrillas": return "figure.hiking"
        case "trapecios": return "shield.lefthalf.filled"
        case "antebrazos": return "hand.raised.fill"
        default: return "dumbbell.fill"
        }
    }
}

// MARK: - My routines

private struct MyRoutinesCard: View {

    @ObservedObject var vm: MyRoutinesViewModel
    let uid: String

    let onDetails: (WorkoutRoutine) -> Void

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
