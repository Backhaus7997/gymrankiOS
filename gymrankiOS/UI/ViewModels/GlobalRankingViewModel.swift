//
//  GlobalRankingViewModel.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 05/03/2026.
//

import Foundation
import FirebaseFirestore

@MainActor
final class GlobalRankingVM: ObservableObject {

    struct UserRow: Identifiable {
        let id: String
        let name: String
        let role: String
        let points: Int
    }

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var top3: [UserRow] = []
    @Published var rest: [RankingRow] = []
    @Published var me: RankingMe = .init(rank: 0, points: 0)

    private let db = Firestore.firestore()

    func load(sessionUserId: String, limit: Int = 100) async {
        let myUid = sessionUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !myUid.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // ✅ Requiere field: globalScore (Int) en users
            let snap = try await db.collection("users")
                .order(by: "globalScore", descending: true)
                .limit(to: limit)
                .getDocuments()

            let users: [UserRow] = snap.documents.map { doc in
                let d = doc.data()

                let name = (d["fullName"] as? String)
                    ?? (d["username"] as? String)
                    ?? (d["handle"] as? String)
                    ?? ((d["email"] as? String)?.split(separator: "@").first.map(String.init))
                    ?? "Sin nombre"

                let role = (d["experience"] as? String) ?? "Competidor/a"

                let points = (d["globalScore"] as? Int)
                    ?? Int((d["globalScore"] as? Int64) ?? 0)

                return UserRow(id: doc.documentID, name: name, role: role, points: points)
            }

            top3 = Array(users.prefix(3))

            let afterTop = users.dropFirst(3)
            rest = afterTop.enumerated().map { idx, u in
                RankingRow(rank: idx + 4, name: u.name, role: u.role, points: u.points)
            }

            if let idx = users.firstIndex(where: { $0.id == myUid }) {
                me = RankingMe(rank: idx + 1, points: users[idx].points)
            } else {
                me = .init(rank: 0, points: 0)
            }

        } catch {
            errorMessage = error.localizedDescription
            top3 = []
            rest = []
            me = .init(rank: 0, points: 0)
        }
    }
}
