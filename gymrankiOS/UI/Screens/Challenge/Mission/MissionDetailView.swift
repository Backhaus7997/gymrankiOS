//
//  MissionDetailView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 02/03/2026.
//

import SwiftUI

struct MissionDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let template: MissionTemplate
    let isJoined: Bool
    let onJoined: () -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?

    private let repo = MissionRepository()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 14) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        headerCard
                        infoRow

                        if let goal = template.goalWorkouts {
                            goalCard(goal)
                        }

                        joinButton

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
        .navigationBarBackButtonHidden(true)
    }

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
        .padding(.horizontal, 16)
        .padding(.top, 10)
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

            Text(template.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(2)

            Text(template.subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
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
        .padding(.horizontal, 16)
    }

    private var infoRow: some View {
        HStack(spacing: 10) {
            infoPill(title: "Nivel", value: template.levelDisplay)
            infoPill(title: "Duración", value: template.durationText)
            infoPill(title: "Puntos", value: "\(template.points)")
        }
        .padding(.horizontal, 16)
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }

    private func goalCard(_ goal: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "target")
                .foregroundColor(Color.appGreen.opacity(0.95))
            Text("Objetivo: \(goal) entrenamientos")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }

    private var joinButton: some View {
        Button {
            Task { await join() }
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    SwiftUI.ProgressView().tint(.white.opacity(0.95))
                } else {
                    Image(systemName: isJoined ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(isJoined ? "Ya aceptaste esta misión" : "Aceptar misión")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.95))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isJoined ? Color.white.opacity(0.08) : Color.appGreen.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isJoined ? Color.white.opacity(0.12) : Color.appGreen.opacity(0.55), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isJoined || isLoading)
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    @MainActor
    private func join() async {
        let templateId = template.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !templateId.isEmpty else { return }

        let uid = session.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            errorMessage = "No hay usuario logueado (uid vacío)."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await repo.joinMission(uid: uid, templateId: templateId)
            onJoined()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
