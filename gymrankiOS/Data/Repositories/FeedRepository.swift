//
//  FeedRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import Foundation
import FirebaseFirestore

final class FeedRepository {

    static let shared = FeedRepository()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Public users

    func fetchPublicUsers(limit: Int = 30) async throws -> [UserProfile] {
        let snap = try await db.collection("users")
            .whereField("feedVisibility", isEqualTo: "PUBLIC")
            .limit(to: max(1, min(limit, 100)))
            .getDocuments()

        return snap.documents.compactMap { doc in
            UserProfile.fromFirestore(docId: doc.documentID, data: doc.data())
        }
    }

    // MARK: - Friends (accepted)

    func fetchAcceptedFriendUids(myUid: String) async throws -> [String] {
        let clean = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(clean)
            .collection("friends")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments()

        // documentId suele ser friendUid, pero también soportamos otherUid field
        return snap.documents.compactMap { d in
            (d.data()["otherUid"] as? String) ?? d.documentID
        }
    }

    // MARK: - Latest routines per user (preview)

    func fetchLatestRoutines(for uid: String, limit: Int = 3) async throws -> [FeedRoutinePreview] {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(clean)
            .collection("routines")
            .order(by: "createdAt", descending: true)
            .limit(to: max(1, min(limit, 10)))
            .getDocuments()

        return snap.documents.map { doc in
            Self.mapRoutineDocToPreview(doc)
        }
    }

    // MARK: - Public feed profiles (1 card per profile)

    func fetchPublicFeedProfiles(
        excludingUid myUid: String,
        limitUsers: Int = 30,
        limitRoutinesPerUser: Int = 3
    ) async throws -> [FeedProfileItem] {

        // 1) traer usuarios públicos
        let usersSnap = try await db.collection("users")
            .whereField("feedVisibility", isEqualTo: "PUBLIC")
            .limit(to: max(1, min(limitUsers, 100)))
            .getDocuments()

        let profiles: [UserProfile] = usersSnap.documents.compactMap {
            UserProfile.fromFirestore(docId: $0.documentID, data: $0.data())
        }
        .filter { $0.uid != myUid }

        var out: [FeedProfileItem] = []
        out.reserveCapacity(profiles.count)

        // 2) por cada perfil, traer sus últimas rutinas públicas
        for p in profiles {
            let routinesSnap = try await db.collection("users")
                .document(p.uid)
                .collection("routines")
                .whereField("authorFeedVisibility", isEqualTo: "PUBLIC")
                .order(by: "createdAt", descending: true)
                .limit(to: max(0, min(limitRoutinesPerUser, 10)))
                .getDocuments()

            // ✅ ACA estaba el bug: devolvías WorkoutRoutine, pero FeedProfileItem espera FeedRoutinePreview
            let routines: [FeedRoutinePreview] = routinesSnap.documents.map { doc in
                Self.mapRoutineDocToPreview(doc)
            }

            out.append(.init(profile: p, latestRoutines: routines))
        }

        return out
    }

    // MARK: - Mapping helpers

    private static func mapRoutineDocToPreview(_ doc: QueryDocumentSnapshot) -> FeedRoutinePreview {
        let d = doc.data()

        let title = (d["title"] as? String) ?? "Entrenamiento"
        let createdAt = (d["createdAt"] as? Timestamp)?.dateValue()

        let exercises = d["exercises"] as? [[String: Any]] ?? []
        let summary: [FeedWorkoutExercise] = exercises.prefix(3).map { ex in
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
