//
//  RankingViewModel.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

@MainActor
final class RankingVM: ObservableObject {

    enum Segment {
        case weekly, monthly, history
    }

    struct GymContext {
        let gymId: String
        let gymName: String
        let location: String
    }

    struct UserRow: Identifiable {
        let id: String
        let name: String
        let role: String
        let points: Int
    }

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var gymName: String = "—"
    @Published var location: String = "—"

    // ✅ NUEVO: comunidad
    @Published var communityCount: Int = 0

    @Published var top3: [UserRow] = []
    @Published var rest: [RankingRow] = []
    @Published var me: RankingMe = .init(rank: 0, points: 0)

    private let db = Firestore.firestore()

    // MARK: - Public

    func load(segment: Segment, sessionUserId: String) async {
        let uid = sessionUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await UserRepository.shared.ensureScoreFields(uid: uid)

            let gym = try await fetchMyGymContext(uid: uid)
            gymName = gym.gymName
            location = gym.location

            // ✅ calcular comunidad (NO depende del ranking limit)
            communityCount = try await fetchCommunityCount(gymId: gym.gymId)

            let (users, myPoints, myRank) = try await fetchRankingUsers(
                gymId: gym.gymId,
                segment: segment,
                myUid: uid
            )

            top3 = Array(users.prefix(3))

            let afterTop = users.dropFirst(3)
            rest = afterTop.enumerated().map { idx, u in
                RankingRow(rank: idx + 4, name: u.name, role: u.role, points: u.points)
            }

            me = RankingMe(rank: myRank, points: myPoints)

        } catch {
            errorMessage = error.localizedDescription
            top3 = []
            rest = []
            me = .init(rank: 0, points: 0)
            communityCount = 0
        }
    }

    // MARK: - Private

    private func fetchMyGymContext(uid: String) async throws -> GymContext {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else {
            throw NSError(domain: "RankingVM", code: 1, userInfo: [NSLocalizedDescriptionKey: "No existe users/{uid}"])
        }

        guard let gymId = data["gymId"] as? String, !gymId.isEmpty else {
            throw NSError(domain: "RankingVM", code: 2, userInfo: [NSLocalizedDescriptionKey: "El usuario no tiene gymId"])
        }

        let gymName = (data["gymNameCache"] as? String) ?? "Mi gimnasio"
        let location = (data["gymCityCache"] as? String) ?? "—"

        return GymContext(gymId: gymId, gymName: gymName, location: location)
    }

    private func pointsField(for segment: Segment) -> String {
        switch segment {
        case .weekly: return "scoreWeekly"
        case .monthly: return "scoreMonthly"
        case .history: return "scoreAllTime"
        }
    }

    private func fetchRankingUsers(
        gymId: String,
        segment: Segment,
        myUid: String,
        limit: Int = 100
    ) async throws -> ([UserRow], Int, Int) {

        let field = pointsField(for: segment)

        do {
            let snap = try await db.collection("users")
                .whereField("gymId", isEqualTo: gymId)
                .order(by: field, descending: true)
                .limit(to: limit)
                .getDocuments()

            let users = mapUsers(snap.documents, pointsField: field)
            return computeMe(users: users, myUid: myUid)

        } catch {
            let snap = try await db.collection("users")
                .whereField("gymId", isEqualTo: gymId)
                .limit(to: limit)
                .getDocuments()

            var users = mapUsers(snap.documents, pointsField: field)
            users.sort { $0.points > $1.points }
            return computeMe(users: users, myUid: myUid)
        }
    }

    private func mapUsers(_ docs: [QueryDocumentSnapshot], pointsField: String) -> [UserRow] {
        docs.map { doc in
            let d = doc.data()

            let name = (d["fullName"] as? String)
                ?? (d["username"] as? String)
                ?? (d["handle"] as? String)
                ?? ((d["email"] as? String)?.split(separator: "@").first.map(String.init))
                ?? "Sin nombre"

            let role = (d["experience"] as? String) ?? "Competidor/a"

            let points = (d[pointsField] as? Int)
                ?? Int((d[pointsField] as? Int64) ?? 0)

            return UserRow(
                id: doc.documentID,
                name: name,
                role: role,
                points: points
            )
        }
    }

    private func computeMe(users: [UserRow], myUid: String) -> ([UserRow], Int, Int) {
        if let idx = users.firstIndex(where: { $0.id == myUid }) {
            return (users, users[idx].points, idx + 1)
        }
        return (users, 0, 0)
    }

    // ✅ Comunidad real (COUNT)
    private func fetchCommunityCount(gymId: String) async throws -> Int {

        // Si tu Firebase SDK soporta aggregation count():
        // (si esto te da error de compilación, usa el fallback de abajo)

        do {
            let query = db.collection("users")
                .whereField("gymId", isEqualTo: gymId)

            let agg = try await query.count.getAggregation(source: .server)
            return Int(agg.count)

        } catch {
            // ✅ Fallback: trae docs (para gimnasios chicos va perfecto)
            let snap = try await db.collection("users")
                .whereField("gymId", isEqualTo: gymId)
                .getDocuments()
            return snap.documents.count
        }
    }
}
