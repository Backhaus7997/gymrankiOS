//
//  FeedRepository.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

final class FeedRepository {

    static let shared = FeedRepository()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Users (para tab Público)

    /// Trae usuarios (sin filtrar por feedVisibility). La UI decide qué muestra.
    func fetchUsers(limit: Int = 30) async throws -> [UserProfile] {
        let snap = try await db.collection("users")
            .limit(to: max(1, min(limit, 200)))
            .getDocuments()

        return snap.documents.compactMap { doc in
            UserProfile.fromFirestore(docId: doc.documentID, data: doc.data())
        }
    }

    // MARK: - Friends (accepted uids)

    func fetchFriendsUids(myUid: String) async throws -> [String] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(me)
            .collection("friends")
            .whereField("status", isEqualTo: FriendStatus.accepted.rawValue)
            .getDocuments()

        return snap.documents.map { ($0.data()["otherUid"] as? String) ?? $0.documentID }
    }

    // MARK: - Latest routines per user (preview) PUBLIC ONLY (para tab Público)

    func fetchLatestRoutinePreviews(for uid: String, limit: Int = 3) async throws -> [FeedRoutinePreview] {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(clean)
            .collection("routines")
            .whereField("authorFeedVisibility", isEqualTo: "PUBLIC") // solo rutinas públicas
            .order(by: "createdAt", descending: true)
            .limit(to: max(1, min(limit, 10)))
            .getDocuments()

        return snap.documents.map { doc in
            let d = doc.data()

            let title = (d["title"] as? String) ?? "Entrenamiento"
            let createdAt = (d["createdAt"] as? Timestamp)?.dateValue()

            // ✅ OJO: acá NO limitamos ejercicios (para "ver más entrenamientos" querés todos)
            let exercises = d["exercises"] as? [[String: Any]] ?? []
            let summary: [FeedWorkoutExercise] = exercises.map { ex in
                let name = (ex["name"] as? String) ?? "-"
                let repsInt = (ex["reps"] as? Int) ?? 0
                let usesBW = (ex["usesBodyweight"] as? Bool) ?? false
                let w = ex["weightKg"] as? Int

                let reps = repsInt > 0 ? "\(repsInt)" : "—"
                let weight: String = usesBW ? "BW" : (w != nil ? "\(w!) kg" : "—")

                return FeedWorkoutExercise(name: name, reps: reps, weight: weight)
            }

            return FeedRoutinePreview(
                id: doc.documentID,
                title: title,
                createdAt: createdAt,
                exercisesSummary: summary,
                timeAgo: Self.timeAgo(from: createdAt)
            )
        }
    }

    // MARK: - Public feed (1 card por perfil)

    /// Devuelve 1 item por perfil. Rutinas SOLO si el perfil tiene feedVisibility == PUBLIC.
    func fetchPublicFeedProfiles(excludingUid myUid: String, limitUsers: Int = 30, limitRoutinesPerUser: Int = 3) async throws -> [FeedProfileItem] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) usuarios (sin filtrar por feedVisibility)
        let profiles = try await fetchUsers(limit: limitUsers)
            .filter { !$0.uid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { $0.uid != me }

        var out: [FeedProfileItem] = []
        out.reserveCapacity(profiles.count)

        for p in profiles {
            // 2) rutinas solo si el usuario es PUBLIC
            let isPublicProfile = (p.feedVisibility == .public)

            let routines: [FeedRoutinePreview] = isPublicProfile
                ? (try await fetchLatestRoutinePreviews(for: p.uid, limit: limitRoutinesPerUser))
                : []

            out.append(.init(profile: p, latestRoutines: routines))
        }

        // ordenar por actividad
        return out.sorted {
            let d0 = $0.latestRoutines.first?.createdAt ?? .distantPast
            let d1 = $1.latestRoutines.first?.createdAt ?? .distantPast
            return d0 > d1
        }
    }

    // MARK: - Friends feed (1 card por perfil, solo accepted)

    /// Devuelve 1 item por cada amigo aceptado. Rutinas visibles para AMIGOS:
    /// - Si el perfil está PRIVATE => no devolvemos rutinas
    /// - Si está PUBLIC o FRIENDS_ONLY => devolvemos rutinas (filtrando por authorFeedVisibility)
    func fetchFriendFeedProfiles(myUid: String, limitRoutinesPerUser: Int = 3) async throws -> [FeedProfileItem] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let friendUids = try await fetchFriendsUids(myUid: me)
        guard !friendUids.isEmpty else { return [] }

        // traer perfiles de amigos en batches de 10 (whereIn)
        let chunks = friendUids.chunked(into: 10)
        var profiles: [UserProfile] = []
        profiles.reserveCapacity(friendUids.count)

        for chunk in chunks {
            let snap = try await db.collection("users")
                .whereField("uid", in: chunk)
                .getDocuments()

            profiles.append(contentsOf: snap.documents.compactMap {
                UserProfile.fromFirestore(docId: $0.documentID, data: $0.data())
            })
        }

        // 1 item por perfil
        var out: [FeedProfileItem] = []
        out.reserveCapacity(profiles.count)

        for p in profiles {
            let canSeeRoutines: Bool = (p.feedVisibility != .private)

            let routines: [FeedRoutinePreview] = canSeeRoutines
                ? (try await fetchLatestRoutinePreviewsForFriendContext(uid: p.uid, limit: limitRoutinesPerUser))
                : []

            out.append(.init(profile: p, latestRoutines: routines))
        }

        // ordenar por actividad
        return out.sorted {
            let d0 = $0.latestRoutines.first?.createdAt ?? .distantPast
            let d1 = $1.latestRoutines.first?.createdAt ?? .distantPast
            return d0 > d1
        }
    }

    /// Amigos: traemos latest 10 por createdAt y filtramos en cliente por authorFeedVisibility
    /// para no depender de índice compuesto extra.
    private func fetchLatestRoutinePreviewsForFriendContext(uid: String, limit: Int) async throws -> [FeedRoutinePreview] {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(clean)
            .collection("routines")
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments()

        // visibles para amigos
        let allowed: Set<String> = ["PUBLIC", "FRIENDS_ONLY"]

        let mapped: [FeedRoutinePreview] = snap.documents.compactMap { doc in
            let d = doc.data()
            let vis = (d["authorFeedVisibility"] as? String) ?? "PUBLIC"
            guard allowed.contains(vis) else { return nil }

            let title = (d["title"] as? String) ?? "Entrenamiento"
            let createdAt = (d["createdAt"] as? Timestamp)?.dateValue()

            // ✅ NO limitar ejercicios
            let exercises = d["exercises"] as? [[String: Any]] ?? []
            let summary: [FeedWorkoutExercise] = exercises.map { ex in
                let name = (ex["name"] as? String) ?? "-"
                let repsInt = (ex["reps"] as? Int) ?? 0
                let usesBW = (ex["usesBodyweight"] as? Bool) ?? false
                let w = ex["weightKg"] as? Int

                let reps = repsInt > 0 ? "\(repsInt)" : "—"
                let weight: String = usesBW ? "BW" : (w != nil ? "\(w!) kg" : "—")
                return FeedWorkoutExercise(name: name, reps: reps, weight: weight)
            }

            return FeedRoutinePreview(
                id: doc.documentID,
                title: title,
                createdAt: createdAt,
                exercisesSummary: summary,
                timeAgo: Self.timeAgo(from: createdAt)
            )
        }

        return Array(mapped.prefix(max(0, min(limit, 10))))
    }

    private static func timeAgo(from date: Date?) -> String {
        guard let date else { return "—" }
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 60 { return "Recién" }
        let mins = secs / 60
        if mins < 60 { return "Hace \(mins) min" }
        let hours = mins / 60
        if hours < 24 { return "Hace \(hours) h" }
        let days = hours / 24
        return "Hace \(days) d"
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            result.append(Array(self[idx..<end]))
            idx = end
        }
        return result
    }
}
