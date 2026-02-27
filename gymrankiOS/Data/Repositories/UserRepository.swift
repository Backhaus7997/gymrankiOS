//
//  UserRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import Foundation
import FirebaseFirestore

final class UserRepository {
    static let shared = UserRepository()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Create / Update base user

    func createUserDocumentIfNeeded(uid: String, email: String) async throws {
        let ref = db.collection("users").document(uid)
        let snap = try await ref.getDocument()

        if snap.exists { return }

        try await ref.setData([
            "uid": uid,
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "profileCompleted": false,
            "feedVisibility": FeedVisibility.public.rawValue
        ], merge: true)
    }

    func updateProfile(
        uid: String,
        fullName: String,
        birthdate: Date,
        weightKg: Double,
        heightCm: Double,
        gender: String,
        experience: String
    ) async throws {
        let ref = db.collection("users").document(uid)

        try await ref.setData([
            "fullName": fullName,
            "birthdate": Timestamp(date: birthdate),
            "weightKg": weightKg,
            "heightCm": heightCm,
            "gender": gender,
            "experience": experience,
            "profileCompleted": true,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
}

// MARK: - Gym

extension UserRepository {
    func setGym(uid: String, gymId: String, gymNameCache: String? = nil, gymCityCache: String? = nil) async throws {
        var data: [String: Any] = [
            "gymId": gymId,
            "gymSelectedAt": Timestamp(date: Date())
        ]
        if let gymNameCache { data["gymNameCache"] = gymNameCache }
        if let gymCityCache { data["gymCityCache"] = gymCityCache }

        try await db
            .collection("users")
            .document(uid)
            .setData(data, merge: true)
    }
}

// MARK: - Profiles (NEW)

extension UserRepository {

    /// Trae un perfil liviano (UserProfile) desde users/{uid}
    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        let doc = try await db.collection("users").document(clean).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return mapUserProfile(docId: doc.documentID, data: data)
    }

    /// Trae muchos perfiles por uid (batch de a 10 para whereIn)
    func fetchUserProfiles(uids: [String]) async throws -> [UserProfile] {
        let clean = Array(Set(uids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }

        guard !clean.isEmpty else { return [] }

        // Firestore: whereField(in:) suele limitar a 10 elementos
        let chunks = clean.chunked(into: 10)

        var out: [UserProfile] = []
        out.reserveCapacity(clean.count)

        for chunk in chunks {
            let snap = try await db.collection("users")
                .whereField("uid", in: chunk)
                .getDocuments()

            let mapped = snap.documents.compactMap { mapUserProfile(docId: $0.documentID, data: $0.data()) }
            out.append(contentsOf: mapped)
        }

        // opcional: mantener el orden del input (si te importa)
        let indexMap = Dictionary(uniqueKeysWithValues: clean.enumerated().map { ($0.element, $0.offset) })
        return out.sorted { (indexMap[$0.uid] ?? 0) < (indexMap[$1.uid] ?? 0) }
    }

    /// Sugerencias: trae usuarios públicos (filtrás luego los que ya son amigos/requested)
    func fetchSuggestedPublicProfiles(limit: Int = 30) async throws -> [UserProfile] {
        let snap = try await db.collection("users")
            .whereField("feedVisibility", isEqualTo: FeedVisibility.public.rawValue)
            .limit(to: max(1, min(limit, 100)))
            .getDocuments()

        return snap.documents.compactMap { mapUserProfile(docId: $0.documentID, data: $0.data()) }
    }

    /// Cambia visibilidad global del usuario (PUBLIC / FRIENDS_ONLY / PRIVATE)
    func updateFeedVisibility(uid: String, value: FeedVisibility) async throws {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        try await db.collection("users")
            .document(clean)
            .setData([
                "feedVisibility": value.rawValue,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
    }

    // MARK: - Mapping

    private func mapUserProfile(docId: String, data: [String: Any]) -> UserProfile {
        UserProfile.fromFirestore(docId: docId, data: data)
    }
}

// MARK: - Helpers

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        result.reserveCapacity((count / size) + 1)

        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            result.append(Array(self[idx..<end]))
            idx = end
        }
        return result
    }
}

extension UserRepository {

    func updateAvatarUrl(uid: String, avatarUrl: String) async throws {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        try await db.collection("users")
            .document(clean)
            .setData([
                "avatarUrl": avatarUrl,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
    }
}
