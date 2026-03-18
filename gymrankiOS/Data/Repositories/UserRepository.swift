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

        let now = Date()
        let weeklyKey = ScoreKeys.weekKey(for: now)
        let monthlyKey = ScoreKeys.monthKey(for: now)

        try await ref.setData([
            "uid": uid,
            "email": email,
            "createdAt": Timestamp(date: now),
            "profileCompleted": false,
            "feedVisibility": FeedVisibility.public.rawValue,

            // legacy
            "score": 0,

            // nuevos
            "scoreWeekly": 0,
            "scoreMonthly": 0,
            "scoreAllTime": 0,
            "scoreWeeklyKey": weeklyKey,
            "scoreMonthlyKey": monthlyKey
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

    /// Migración silenciosa: si faltan los campos nuevos, los crea usando legacy `score`.
    func ensureScoreFields(uid: String) async throws {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let ref = db.collection("users").document(clean)
        let doc = try await ref.getDocument()
        guard let data = doc.data() else { return }

        let now = Date()
        let weeklyKey = ScoreKeys.weekKey(for: now)
        let monthlyKey = ScoreKeys.monthKey(for: now)

        let legacy = (data["score"] as? Int) ?? 0

        var updates: [String: Any] = [:]
        if data["scoreWeekly"] == nil { updates["scoreWeekly"] = legacy }
        if data["scoreMonthly"] == nil { updates["scoreMonthly"] = legacy }
        if data["scoreAllTime"] == nil { updates["scoreAllTime"] = legacy }
        if data["scoreWeeklyKey"] == nil { updates["scoreWeeklyKey"] = weeklyKey }
        if data["scoreMonthlyKey"] == nil { updates["scoreMonthlyKey"] = monthlyKey }

        if !updates.isEmpty {
            updates["updatedAt"] = FieldValue.serverTimestamp()
            try await ref.setData(updates, merge: true)
        }
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

    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        let doc = try await db.collection("users").document(clean).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return mapUserProfile(docId: doc.documentID, data: data)
    }

    func fetchUserProfiles(uids: [String]) async throws -> [UserProfile] {
        let clean = Array(Set(uids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }

        guard !clean.isEmpty else { return [] }

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

        let indexMap = Dictionary(uniqueKeysWithValues: clean.enumerated().map { ($0.element, $0.offset) })
        return out.sorted { (indexMap[$0.uid] ?? 0) < (indexMap[$1.uid] ?? 0) }
    }

    func fetchSuggestedPublicProfiles(limit: Int = 30) async throws -> [UserProfile] {
        let snap = try await db.collection("users")
            .whereField("feedVisibility", isEqualTo: FeedVisibility.public.rawValue)
            .limit(to: max(1, min(limit, 100)))
            .getDocuments()

        return snap.documents.compactMap { mapUserProfile(docId: $0.documentID, data: $0.data()) }
    }

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
    
    func updateCoverUrl(uid: String, coverUrl: String) async throws {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        try await db.collection("users")
            .document(clean)
            .setData([
                "coverUrl": coverUrl,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
    }
}

// MARK: - Check-in daily

extension UserRepository {

    /// Claim de check-in diario:
    /// - Evita doble cobro por día (lastGymCheckInDay)
    /// - Resetea scoreWeekly/scoreMonthly si cambió el período (por keys)
    /// - Incrementa scoreWeekly/scoreMonthly/scoreAllTime (y también legacy score por ahora)
    func claimGymCheckIn(uid: String, dayKey: String, points: Int = 20) async throws -> Bool {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }

        let ref = db.collection("users").document(clean)

        return try await withCheckedThrowingContinuation { cont in
            db.runTransaction({ tx, errorPointer -> Any? in
                do {
                    let snap = try tx.getDocument(ref)
                    let data = snap.data() ?? [:]
                    let lastDay = data["lastGymCheckInDay"] as? String

                    if lastDay == dayKey {
                        return false
                    }

                    tx.setData([
                        "lastGymCheckInDay": dayKey,
                        "lastGymCheckInAt": FieldValue.serverTimestamp(),
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: ref, merge: true)

                    let now = Date()
                    let currentWeeklyKey = ScoreKeys.weekKey(for: now)
                    let currentMonthlyKey = ScoreKeys.monthKey(for: now)

                    let storedWeeklyKey = data["scoreWeeklyKey"] as? String
                    let storedMonthlyKey = data["scoreMonthlyKey"] as? String

                    let legacyScore = (data["score"] as? Int) ?? 0

                    var updates: [String: Any] = [:]

                    if storedWeeklyKey != currentWeeklyKey {
                        updates["scoreWeekly"] = 0
                        updates["scoreWeeklyKey"] = currentWeeklyKey
                    } else if data["scoreWeekly"] == nil {
                        updates["scoreWeekly"] = legacyScore
                        updates["scoreWeeklyKey"] = currentWeeklyKey
                    }

                    if storedMonthlyKey != currentMonthlyKey {
                        updates["scoreMonthly"] = 0
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    } else if data["scoreMonthly"] == nil {
                        updates["scoreMonthly"] = legacyScore
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    }

                    if data["scoreAllTime"] == nil {
                        updates["scoreAllTime"] = legacyScore
                    }

                    updates["scoreWeekly"] = FieldValue.increment(Int64(points))
                    updates["scoreMonthly"] = FieldValue.increment(Int64(points))
                    updates["scoreAllTime"] = FieldValue.increment(Int64(points))
                    updates["score"] = FieldValue.increment(Int64(points))

                    tx.setData(updates, forDocument: ref, merge: true)

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { result, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume(returning: (result as? Bool) ?? false)
            })
        }
    }
}

// MARK: - Complete challenge/mission + award points

extension UserRepository {

    func completeChallengeAndAwardPoints(
        uid: String,
        templateId: String,
        points: Int
    ) async throws -> Bool {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTpl = templateId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty, !cleanTpl.isEmpty else { return false }

        let userRef = db.collection("users").document(cleanUid)
        let itemRef = db.collection("user_challenges").document("\(cleanUid)_\(cleanTpl)")

        return try await runAwardTransaction(
            userRef: userRef,
            itemRef: itemRef,
            itemStatusField: "status",
            itemCompletedValue: UserChallengeStatus.completed,
            points: points,
            extraItemWrites: { tx, nowMs in
                tx.setData([
                    "uid": cleanUid,
                    "templateId": cleanTpl,
                    "status": UserChallengeStatus.completed,
                    "updatedAt": nowMs
                ], forDocument: itemRef, merge: true)
            }
        )
    }

    func completeMissionAndAwardPoints(
        uid: String,
        templateId: String,
        points: Int
    ) async throws -> Bool {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTpl = templateId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty, !cleanTpl.isEmpty else { return false }

        let userRef = db.collection("users").document(cleanUid)
        let itemRef = db.collection("user_missions").document("\(cleanUid)_\(cleanTpl)")

        return try await runAwardTransaction(
            userRef: userRef,
            itemRef: itemRef,
            itemStatusField: "status",
            itemCompletedValue: UserMissionStatus.completed,
            points: points,
            extraItemWrites: { tx, nowMs in
                tx.setData([
                    "uid": cleanUid,
                    "templateId": cleanTpl,
                    "status": UserMissionStatus.completed,
                    "updatedAt": nowMs
                ], forDocument: itemRef, merge: true)
            }
        )
    }

    // MARK: - Core transaction helper

    private func runAwardTransaction(
        userRef: DocumentReference,
        itemRef: DocumentReference,
        itemStatusField: String,
        itemCompletedValue: String,
        points: Int,
        extraItemWrites: @escaping (_ tx: Transaction, _ nowMs: Int64) -> Void
    ) async throws -> Bool {

        try await withCheckedThrowingContinuation { cont in
            db.runTransaction({ tx, errorPointer -> Any? in
                do {
                    let itemSnap = try tx.getDocument(itemRef)
                    let userSnap = try tx.getDocument(userRef)

                    let itemData = itemSnap.data() ?? [:]
                    let userData = userSnap.data() ?? [:]

                    let currentStatus = itemData[itemStatusField] as? String
                    if currentStatus == itemCompletedValue {
                        return false
                    }

                    let now = Date()
                    let currentWeeklyKey = ScoreKeys.weekKey(for: now)
                    let currentMonthlyKey = ScoreKeys.monthKey(for: now)

                    let storedWeeklyKey = userData["scoreWeeklyKey"] as? String
                    let storedMonthlyKey = userData["scoreMonthlyKey"] as? String

                    let legacyScore = (userData["score"] as? Int) ?? 0
                    let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)

                    // ✅ WRITES después
                    extraItemWrites(tx, nowMs)

                    // Base updates
                    var updates: [String: Any] = [
                        "updatedAt": FieldValue.serverTimestamp(),

                        // mantener legacy por compatibilidad
                        "score": FieldValue.increment(Int64(points)),

                        "scoreWeekly": FieldValue.increment(Int64(points)),
                        "scoreMonthly": FieldValue.increment(Int64(points)),
                        "scoreAllTime": FieldValue.increment(Int64(points))
                    ]

                    // init faltantes (usuarios viejos)
                    if userData["scoreAllTime"] == nil { updates["scoreAllTime"] = legacyScore }
                    if userData["scoreWeekly"] == nil { updates["scoreWeekly"] = legacyScore }
                    if userData["scoreMonthly"] == nil { updates["scoreMonthly"] = legacyScore }
                    if userData["scoreWeeklyKey"] == nil { updates["scoreWeeklyKey"] = currentWeeklyKey }
                    if userData["scoreMonthlyKey"] == nil { updates["scoreMonthlyKey"] = currentMonthlyKey }

                    // reset semanal si cambió key
                    if let storedWeeklyKey, storedWeeklyKey != currentWeeklyKey {
                        updates["scoreWeekly"] = Int64(points)        // reset + sumar
                        updates["scoreWeeklyKey"] = currentWeeklyKey
                    } else {
                        updates["scoreWeeklyKey"] = currentWeeklyKey  // asegurar
                    }

                    // reset mensual si cambió key
                    if let storedMonthlyKey, storedMonthlyKey != currentMonthlyKey {
                        updates["scoreMonthly"] = Int64(points)
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    } else {
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    }

                    tx.setData(updates, forDocument: userRef, merge: true)

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }, completion: { result, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume(returning: (result as? Bool) ?? false)
            })
        }
    }
}

// MARK: - Complete bet + award points

extension UserRepository {

    func completeBetAndAwardPoints(
        uid: String,
        templateId: String,
        points: Int
    ) async throws -> Bool {

        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTpl = templateId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty, !cleanTpl.isEmpty else { return false }

        let userRef = db.collection("users").document(cleanUid)
        let itemRef = db.collection("user_bets").document("\(cleanUid)_\(cleanTpl)")

        return try await runAwardTransaction(
            userRef: userRef,
            itemRef: itemRef,
            itemStatusField: "status",
            itemCompletedValue: UserBetStatus.completed,
            points: points,
            extraItemWrites: { tx, nowMs in
                tx.setData([
                    "uid": cleanUid,
                    "templateId": cleanTpl,
                    "status": UserBetStatus.completed,
                    "completedAt": FieldValue.serverTimestamp(),
                    "updatedAt": nowMs
                ], forDocument: itemRef, merge: true)
            }
        )
    }
}
