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

            VStack(spacing: 14) {

                HStack {
                    Text("Ver detalles")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))

                    Spacer()

                    Button("Cerrar") { dismiss() }
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.appGreen.opacity(0.95))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let err = errorMessage, !err.isEmpty {
                    Text(err)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 10) {
                    statRow(title: "Puntos semanales", value: "\(weekly) pts")
                    statRow(title: "Puntos mensuales", value: "\(monthly) pts")
                    statRow(title: "Puntos globales", value: "\(global) gp")
                    statRow(title: "Nivel", value: "\(level)")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)

                Spacer()
            }

            if isLoading {
                ProgressView().tint(.white)
            }
        }
        .task { await load() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.60))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.92))
        }
    }

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
