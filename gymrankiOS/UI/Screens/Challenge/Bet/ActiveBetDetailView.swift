//
//  ActiveBetDetailView.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 09/03/2026.
//

import SwiftUI

struct ActiveBetDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let active: ChallengesHomeVM.ActiveBet
    let onStatusChanged: () -> Void

    @State private var progress: [Int] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showCongrats = false

    private let repo = BetRepository()
    private let userRepo = UserRepository.shared

    private var uid: String { session.userId.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var completedCount: Int {
        zip(active.template.tasks, progress).filter { $1 >= $0.target }.count
    }

    private var canComplete: Bool {
        completedCount == active.template.tasks.count
    }

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {

                    topBar

                    header

                    tasksCard

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            
            if showCongrats {
                CenterModalOverlay(isPresented: $showCongrats) {
                    CompletionCongratsPopup(
                        kind: .bet, // o .challenge / .mission
                        itemTitle: active.template.title,
                        points: active.template.points,
                        onClose: {
                            showCongrats = false
                            onStatusChanged()
                            dismiss()
                        }
                    )
                    .padding(.horizontal, 18)
                }
                .zIndex(60)
            }

        }
        .safeAreaInset(edge: .bottom) { footer }
        .onAppear {
            progress = active.userBet.progress
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

            Text("Apuesta")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(active.template.title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            HStack(spacing: 10) {
                pill("APUESTA")
                pill(active.template.difficultyDisplay)
                pill(active.template.durationType == "daily" ? "24h" : "3h")
                pill("\(active.template.points) pts")
                Spacer()
            }

            Text("Tareas completadas: \(completedCount)/\(active.template.tasks.count)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))

            SwiftUI.ProgressView(value: Double(completedCount), total: Double(max(active.template.tasks.count, 1)))
                .tint(Color.appGreen.opacity(0.9))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.appGreen.opacity(0.22), lineWidth: 1))
        )
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.90))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var tasksCard: some View {
        VStack(spacing: 12) {
            ForEach(active.template.tasks.indices, id: \.self) { idx in
                taskRow(idx)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
        )
    }

    private func taskRow(_ idx: Int) -> some View {
        let t = active.template.tasks[idx]
        let current = (idx < progress.count) ? progress[idx] : 0
        let done = current >= t.target

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(t.name) • \(current)/\(t.target) \(t.unit)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineLimit(2)

                Text(t.description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    setValue(idx, max(0, current - 1))
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

                Text("\(current)")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .frame(width: 28)

                Button {
                    setValue(idx, min(t.target, current + 1))
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }

            Image(systemName: done ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(done ? Color.appGreen.opacity(0.95) : .white.opacity(0.25))
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    Task { await setStatus(UserBetStatus.cancelled) }
                } label: {
                    Text("Abandonar")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

                Button {
                    if canComplete {
                        Task { await completeAndAward() }
                    } else {
                        errorMessage = "Completá todas las tareas antes de marcar como completado."
                    }
                } label: {
                    Text("Completado")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 16).fill(canComplete ? Color.appGreen.opacity(0.28) : Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(canComplete ? Color.appGreen.opacity(0.55) : Color.white.opacity(0.12), lineWidth: 1))
                        .opacity(canComplete ? 1.0 : 0.65)
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .background(Rectangle().fill(Color.black.opacity(0.20)).ignoresSafeArea())
    }

    private func setValue(_ idx: Int, _ value: Int) {
        guard !uid.isEmpty else { errorMessage = "uid vacío"; return }
        guard idx < active.template.tasks.count else { return }
        guard !isSaving else { return }

        if progress.count != active.template.tasks.count {
            progress = Array(repeating: 0, count: active.template.tasks.count)
        }

        progress[idx] = value

        Task {
            do {
                isSaving = true
                defer { isSaving = false }
                try await repo.updateProgress(uid: uid, templateId: active.template.id, progress: progress)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func setStatus(_ status: String) async {
        guard !uid.isEmpty else { errorMessage = "uid vacío"; return }
        do {
            isSaving = true
            defer { isSaving = false }
            try await repo.setStatus(uid: uid, templateId: active.template.id, status: status)
            onStatusChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func completeAndAward() async {
        guard !uid.isEmpty else { errorMessage = "uid vacío"; return }

        do {
            isSaving = true
            defer { isSaving = false }

            let awarded = try await userRepo.completeBetAndAwardPoints(
                uid: uid,
                templateId: active.template.id,
                points: active.template.points
            )

            if awarded {
                showCongrats = true
                return
            } else {
                onStatusChanged()
                dismiss()
                return
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
