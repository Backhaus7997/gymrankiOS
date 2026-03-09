//
//  RankingDetailsSheet.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import SwiftUI
import FirebaseFirestore

struct RankingDetailsSheet: View {

    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var weekly: Int = 0
    @State private var monthly: Int = 0
    @State private var global: Int = 0
    @State private var level: Int = 1

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()

            VStack(spacing: 18) {

                header

                if let err = errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 20)
                }

                highlightCard
                    .padding(.horizontal, 16)

                statsCard
                    .padding(.horizontal, 16)

                Spacer()
            }

            if isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
        .task { await load() }
        .presentationDetents([.fraction(0.70), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Resumen")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()

            Button("Cerrar") { dismiss() }
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundColor(Color.appGreen.opacity(0.95))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Highlight card

    private var highlightCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.appGreen.opacity(0.16))
                        .frame(width: 58, height: 58)
                        .overlay(
                            Circle()
                                .stroke(Color.appGreen.opacity(0.35), lineWidth: 1)
                        )

                    Image(systemName: "medal.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Progreso Global")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))

                    Text(rankTitle(for: level))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                }

                Spacer()
            }

            HStack(spacing: 12) {
                highlightPill(title: "Nivel", value: "\(level)")
                highlightPill(title: "Rank", value: rankTitle(for: level))
            }

            HStack {
                Text("Puntos globales")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))

                Spacer()

                Text("\(global) gp")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func highlightPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.50))

            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats card

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Puntaje")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))

            VStack(spacing: 14) {
                statRow(title: "Puntos semanales", value: "\(weekly) pts")
                divider
                statRow(title: "Puntos mensuales", value: "\(monthly) pts")
                divider
                statRow(title: "Puntos globales", value: "\(global) gp")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.62))

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.95))
        }
    }

    // MARK: - Rank mapping

    private func rankTitle(for level: Int) -> String {
        switch level {
        case 1...5: return "Bronze"
        case 6...10: return "Iron"
        case 11...15: return "Steel"
        case 16...20: return "Athlete"
        case 21...25: return "Beast"
        case 26...30: return "Titan"
        case 31...40: return "Legend"
        case 41...50: return "Immortal"
        default: return "Olympian"
        }
    }

    // MARK: - Load

    private func load() async {
        let uid = session.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            let d = doc.data() ?? [:]

            weekly = (d["scoreWeekly"] as? Int) ?? Int((d["scoreWeekly"] as? Int64) ?? 0)
            monthly = (d["scoreMonthly"] as? Int) ?? Int((d["scoreMonthly"] as? Int64) ?? 0)
            global = (d["globalScore"] as? Int) ?? Int((d["globalScore"] as? Int64) ?? 0)
            level = (d["globalLevel"] as? Int) ?? ((d["level"] as? Int) ?? 1)

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

