//
//  ChallengeDetailView.swift
//  gymrankiOS
//

import SwiftUI

struct ChallengeDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionManager

    let template: ChallengeTemplate
    let isJoined: Bool
    let onJoined: () -> Void

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCongrats = false

    private let repo = ChallengeRepository()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {

                    topBar

                    headerCard

                    infoRow

                    tagsSection

                    // espacio para que el contenido no quede debajo del footer
                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
        .safeAreaInset(edge: .bottom) {
            footerJoin
        }
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    // MARK: - Top bar

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

            Text(template.title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)

            Spacer()
        }
    }

    // MARK: - Header card

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

                Image(systemName: "flag.checkered")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white.opacity(0.22))
            }

            Text(template.subtitle)
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

    // MARK: - Info row

    private var infoRow: some View {
        HStack(spacing: 10) {
            infoPill(title: "Nivel", value: template.levelDisplay)
            infoPill(title: "Duración", value: template.durationText)
            infoPill(title: "Puntos", value: "\(template.points)")
        }
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

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.70))

            if template.tags.isEmpty {
                Text("Sin tags")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            } else {
                let cols = [GridItem(.adaptive(minimum: 84), spacing: 10)]
                LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                    ForEach(template.tags, id: \.self) { t in
                        TagPill(text: t)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Footer join (fijo abajo)

    private var footerJoin: some View {
        VStack(spacing: 10) {
            // separador visual suave
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)

            Button {
                Task { await join() }
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        SwiftUI.ProgressView()
                            .tint(.white.opacity(0.95))
                    } else {
                        Image(systemName: isJoined ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                    }

                    Text(isJoined ? "Ya estás unido" : "Unirme al desafío")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))

                    Spacer()

                    // un chip a la derecha con el primer tag (queda lindo y no molesta)
                    if let first = template.tags.first, !first.isEmpty {
                        Text(first)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(Color.white.opacity(0.10))
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                }
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 16)
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
            .padding(.bottom, 10)
        }
        // “barra” de fondo para que parezca sticky
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.20))
                .ignoresSafeArea()
        )
    }

    // MARK: - Join

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
            try await repo.joinChallenge(uid: uid, templateId: templateId)
            onJoined()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Tag pill

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundColor(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.appGreen.opacity(0.18))
                    .overlay(Capsule().stroke(Color.appGreen.opacity(0.55), lineWidth: 1))
            )
    }
}
