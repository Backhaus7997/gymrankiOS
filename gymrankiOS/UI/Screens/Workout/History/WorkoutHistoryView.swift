import SwiftUI

struct WorkoutHistoryView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    @StateObject private var vm = WorkoutHistoryViewModel()
    @State private var selectedRoutine: WorkoutRoutine? = nil

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar(title: "Historial de entrenamientos")

                    summaryCard(total: vm.routines.count)

                    content

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }

            centeredRoutineModal
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadIfPossible() }
    }

    private var centeredRoutineModal: some View {
        Group {
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

    private func loadIfPossible() async {
        let uid = session.userId
        guard !uid.isEmpty else { return }
        await vm.load(userId: uid)
    }
    
    // MARK: - TopBar

    private func topBar(title: String) -> some View {
        HStack(spacing: 10) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Spacer()
        }
    }

    // MARK: - Cards

    private func summaryCard(total: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Text("Total de entrenamientos")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            HStack(alignment: .lastTextBaseline) {
                Text("\(total)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.appGreen.opacity(0.95))

                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.15), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var content: some View {
        if session.userId.isEmpty {
            emptyState(
                title: "Iniciá sesión",
                subtitle: "Para ver tu historial tenés que estar logueado."
            )

        } else if vm.isLoading {
            loadingCard

        } else if let err = vm.errorMessage {
            errorCard(err)

        } else if vm.routines.isEmpty {
            emptyState(
                title: "Todavía no registraste entrenamientos",
                subtitle: "Cuando cargues uno, acá vas a ver el detalle con ejercicios, series y pesos."
            )

        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tus entrenamientos")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    ForEach(vm.routines) { routine in
                        historyRoutineCard(routine)
                    }
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cargando...")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }

    private func errorCard(_ err: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Error")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(err)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Button {
                Task { await loadIfPossible() }
            } label: {
                Text("Reintentar")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(width: 150, height: 44)
                    .background(Capsule().fill(Color.appGreen.opacity(0.95)))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "dumbbell")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .padding(.top, 6)

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)

            Spacer(minLength: 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.top, 6)
    }

    private func historyRoutineCard(_ routine: WorkoutRoutine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Button {
                    selectedRoutine = routine
                } label: {
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

            VStack(alignment: .leading, spacing: 8) {
                ForEach(routine.exercises.prefix(3)) { ex in
                    HStack {
                        Text("• \(ex.name)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)

                        Spacer()

                        Text("\(ex.sets)x\(ex.reps)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }
}

// MARK: - ViewModel

@MainActor
final class WorkoutHistoryViewModel: ObservableObject {
    @Published var routines: [WorkoutRoutine] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let repo = RoutineRepository()

    func load(userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            routines = try await repo.fetchRoutines(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
            .environmentObject(SessionManager())
    }
}
