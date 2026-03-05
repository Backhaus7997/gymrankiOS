//
//  ActiveMissionDetailView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 02/03/2026.
//

import SwiftUI

struct ActiveMissionDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let active: ChallengesHomeVM.ActiveMission
    let onStatusChanged: () -> Void

    @State private var isLoading = false
    @State private var showConfirmCancel = false
    @State private var showConfirmComplete = false
    @State private var errorMessage: String?

    private let repo = MissionRepository()
    private let userRepo = UserRepository.shared

    private var uid: String { session.userId.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var totalDays: Int { max(active.template.durationDays, 1) }
    private var elapsedDays: Int { max(0, active.elapsedDays) }
    private var dayIndex: Int { min(elapsedDays + 1, totalDays) }
    private var remainingDays: Int { max(0, totalDays - elapsedDays) }

    private var canMarkCompleted: Bool {
        // ✅ Misiones “instantáneas” (durationDays == 0) se pueden completar siempre
        if active.template.durationDays == 0 { return true }

        guard active.template.durationDays > 0 else { return false }
        return active.elapsedDays >= active.template.durationDays
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {

                    topBar

                    headerCard

                    infoRow

                    progressCard

                    if let goal = active.template.goalWorkouts {
                        goalCard(goal)
                    }

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
        .safeAreaInset(edge: .bottom) { footerButtons }
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
        .confirmationDialog("¿Abandonar misión?", isPresented: $showConfirmCancel, titleVisibility: .visible) {
            Button("Abandonar", role: .destructive) {
                Task { await setStatus(UserMissionStatus.cancelled) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se marcará como abandonada y saldrá de Pendientes.")
        }
        .confirmationDialog("¿Marcar como completada?", isPresented: $showConfirmComplete, titleVisibility: .visible) {
            Button("Completada") {
                Task { await setStatus(UserMissionStatus.completed) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se moverá a Completados y sumará puntos.")
        }
    }

    // MARK: UI

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.92))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Text("Misión")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appGreen.opacity(0.25), lineWidth: 1)
                    )

                Image(systemName: "trophy.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white.opacity(0.22))
            }

            Text(active.template.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(2)

            Text(active.template.subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var infoRow: some View {
        HStack(spacing: 10) {
            infoPill(title: "Nivel", value: active.template.levelDisplay)
            infoPill(title: "Duración", value: durationText)
            infoPill(title: "Puntos", value: "\(active.template.points)")
        }
    }

    private var durationText: String {
        if active.template.durationDays == 0 { return "Instantánea" }
        return "\(active.template.durationDays) días"
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))

            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progreso")
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.90))

            SwiftUI.ProgressView(value: active.progress01)
                .tint(Color.appGreen.opacity(0.9))

            if active.template.durationDays == 0 {
                Text("Misión instantánea • Se completa con una acción.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                Text("Día \(dayIndex) de \(totalDays) • Restan \(remainingDays)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                if !canMarkCompleted {
                    Text("Podés marcarla como completada cuando termines los \(active.template.durationDays) días.")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private func goalCard(_ goal: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "target")
                .foregroundColor(Color.appGreen.opacity(0.95))
            Text("Objetivo: \(goal) entrenos")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appGreen.opacity(0.22), lineWidth: 1)
                )
        )
    }

    private var footerButtons: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(spacing: 12) {
                Button {
                    showConfirmCancel = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Abandonar")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button {
                    if canMarkCompleted {
                        showConfirmComplete = true
                    } else {
                        errorMessage = "Todavía no podés completarla. Te faltan \(remainingDays) día(s)."
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            SwiftUI.ProgressView().tint(.white.opacity(0.95))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                        }
                        Text("Completado")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.95))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(canMarkCompleted ? Color.appGreen.opacity(0.28) : Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(canMarkCompleted ? Color.appGreen.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .opacity(canMarkCompleted ? 1.0 : 0.65)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.20))
                .ignoresSafeArea()
        )
    }

    // MARK: Actions

    @MainActor
    private func setStatus(_ status: String) async {
        guard !uid.isEmpty else {
            errorMessage = "No hay usuario logueado (uid vacío)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if status == UserMissionStatus.completed {
                _ = try await userRepo.completeMissionAndAwardPoints(
                    uid: uid,
                    templateId: active.template.id,
                    points: active.template.points
                )
            } else {
                try await repo.setUserMissionStatus(uid: uid, templateId: active.template.id, status: status)
            }

            onStatusChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
