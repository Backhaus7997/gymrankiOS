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

    func createUserDocumentIfNeeded(uid: String, email: String) async throws {
        let ref = db.collection("users").document(uid)
        let snap = try await ref.getDocument()

        if snap.exists { return }

        try await ref.setData([
            "uid": uid,
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "profileCompleted": false
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

extension UserRepository {
    func setGym(uid: String, gymId: String, gymNameCache: String? = nil) async throws {
        var data: [String: Any] = [
            "gymId": gymId,
            "gymSelectedAt": Timestamp(date: Date())
        ]
        if let gymNameCache {
            data["gymNameCache"] = gymNameCache
        }
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(data, merge: true)
    }
}
