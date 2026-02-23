//
//  ProgressView.swift
//  gymrankiOS
//

import SwiftUI
import Charts

// MARK: - ProgressView

struct ProgressView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ProgressVM()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(title: "Progreso")
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                content
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadIfPossible() }
        .onChange(of: session.userId) { _ in
            Task { await loadIfPossible() }
        }
    }

    private func loadIfPossible() async {
        let uid = session.userId
        guard !uid.isEmpty else { return }
        await vm.load(userId: uid)
    }

    @ViewBuilder
    private var content: some View {
        if session.userId.isEmpty {
            Spacer()
            emptyState(
                title: "Iniciá sesión",
                subtitle: "Para ver tu progreso tenés que estar logueado."
            )
            Spacer()

        } else if vm.isLoading {
            Spacer()
            SwiftUI.ProgressView().tint(.white.opacity(0.9))
            Spacer()

        } else if let err = vm.errorMessage {
            Spacer()
            errorCard(err)
            Spacer()

        } else {
            musclesList
        }
    }

    private var musclesList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(vm.muscles(), id: \.self) { muscle in
                    NavigationLink {
                        ExercisesListView(vm: vm, muscle: muscle)
                    } label: {
                        HStack {
                            Text(muscle)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.92))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.30))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.10), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 120)
        }
    }

    private func errorCard(_ err: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Error")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            Text(err)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.55))

            Button { Task { await loadIfPossible() } } label: {
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white.opacity(0.30))

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
    }

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
}

// MARK: - Exercises list (inline charts, only exercises with evolution)

struct ExercisesListView: View {
    @ObservedObject var vm: ProgressVM
    let muscle: String

    @State private var metricByExercise: [String: ProgressVM.Metric] = [:]

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(muscle)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    // Solo los que tienen puntos (evolución)
                    let exercisesWithData = vm.exercisesForMuscle(muscle)
                        .filter { vm.points(for: $0, metric: .maxWeight).count >= 2 }

                    if exercisesWithData.isEmpty {
                        Text("Todavía no hay registros suficientes para este músculo.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.60))
                            .padding(.top, 10)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(exercisesWithData, id: \.self) { ex in
                                ExerciseInlineCard(
                                    vm: vm,
                                    exerciseName: ex,
                                    metric: Binding(
                                        get: { metricByExercise[ex] ?? .maxWeight },
                                        set: { metricByExercise[ex] = $0 }
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Inline card

private struct ExerciseInlineCard: View {
    @ObservedObject var vm: ProgressVM
    let exerciseName: String
    @Binding var metric: ProgressVM.Metric

    var body: some View {
        let pts = vm.points(for: exerciseName, metric: metric)
        let last = pts.last?.value
        let sessions = pts.count

        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(2)

                    Text("\(sessions) sesiones")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Últ:")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))

                    Text(formatValue(last, metric: metric))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
            }

            Picker("", selection: $metric) {
                ForEach(ProgressVM.Metric.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Chart(pts) { p in
                LineMark(x: .value("Fecha", p.date), y: .value("Valor", p.value))
                PointMark(x: .value("Fecha", p.date), y: .value("Valor", p.value))
            }
            .frame(height: 160)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func formatValue(_ v: Double?, metric: ProgressVM.Metric) -> String {
        guard let v else { return "--" }
        switch metric {
        case .maxWeight:
            return "\(Int(round(v))) kg"
        case .reps:
            return "\(Int(round(v))) reps"
        case .volume:
            return "\(Int(round(v)))"
        }
    }
}
