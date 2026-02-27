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

    // MARK: - Friends (accepted)

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

    // MARK: - Latest routines per user (preview)

    /// Devuelve previews de rutinas. OJO: limita la cantidad de rutinas, NO la cantidad de ejercicios.
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

            // ✅ TODOS los ejercicios (NO prefix(3) acá)
            let exercises = d["exercises"] as? [[String: Any]] ?? []
            let summary: [FeedWorkoutExercise] = exercises.map { ex in
                let name = (ex["name"] as? String) ?? "-"

                // reps puede venir Int o Double
                let repsInt: Int = {
                    if let v = ex["reps"] as? Int { return v }
                    if let v = ex["reps"] as? Double { return Int(v) }
                    return 0
                }()

                let usesBW = (ex["usesBodyweight"] as? Bool) ?? false

                // weightKg puede venir Int o Double
                let weightString: String = {
                    if usesBW { return "BW" }
                    if let v = ex["weightKg"] as? Int { return "\(v) kg" }
                    if let v = ex["weightKg"] as? Double { return "\(Int(v)) kg" }
                    return "—"
                }()

                let reps = repsInt > 0 ? "\(repsInt)" : "—"

                return FeedWorkoutExercise(
                    name: name,
                    reps: reps,
                    weight: weightString
                )
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
    func fetchPublicFeedProfiles(
        excludingUid myUid: String,
        limitUsers: Int = 30,
        limitRoutinesPerUser: Int = 3
    ) async throws -> [FeedProfileItem] {

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

        // ordenar por actividad (el más reciente arriba)
        return out.sorted {
            let d0 = $0.latestRoutines.first?.createdAt ?? .distantPast
            let d1 = $1.latestRoutines.first?.createdAt ?? .distantPast
            return d0 > d1
        }
    }

    // MARK: - Helpers

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
