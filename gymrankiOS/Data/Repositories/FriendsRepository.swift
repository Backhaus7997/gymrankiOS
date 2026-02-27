//
//  FriendsRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 26/02/2026.
//

import Foundation
import FirebaseFirestore

final class FriendsRepository {

    static let shared = FriendsRepository()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Paths

    private func friendsCol(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("friends")
    }

    private func friendDoc(_ uid: String, _ otherUid: String) -> DocumentReference {
        friendsCol(uid).document(otherUid)
    }

    // MARK: - Fetch relations (REAL)

    func fetchRelations(myUid: String) async throws -> [FriendRelation] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let snap = try await friendsCol(me).getDocuments()
        return snap.documents.map { FriendRelation.fromFirestore(docId: $0.documentID, data: $0.data()) }
    }

    func fetchFriendsUids(myUid: String) async throws -> [String] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let snap = try await friendsCol(me)
            .whereField("status", isEqualTo: FriendStatus.accepted.rawValue)
            .getDocuments()

        return snap.documents.map { ($0.data()["otherUid"] as? String) ?? $0.documentID }
    }

    func fetchIncomingRequestUids(myUid: String) async throws -> [String] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let snap = try await friendsCol(me)
            .whereField("status", isEqualTo: FriendStatus.requested.rawValue)
            .whereField("requestedBy", isNotEqualTo: me) // request la inició el otro
            .getDocuments()

        return snap.documents.map { ($0.data()["otherUid"] as? String) ?? $0.documentID }
    }

    func fetchOutgoingRequestUids(myUid: String) async throws -> [String] {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty else { return [] }

        let snap = try await friendsCol(me)
            .whereField("status", isEqualTo: FriendStatus.requested.rawValue)
            .whereField("requestedBy", isEqualTo: me) // request la inicié yo
            .getDocuments()

        return snap.documents.map { ($0.data()["otherUid"] as? String) ?? $0.documentID }
    }

    // MARK: - Actions (REAL)

    /// Envia solicitud: crea 2 docs (en mi user y en el otro user) con status=requested
    func sendRequest(myUid: String, to otherUid: String) async throws {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        let now = Date()
        let payloadMine: [String: Any] = [
            "otherUid": other,
            "status": FriendStatus.requested.rawValue,
            "requestedBy": me,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        let payloadOther: [String: Any] = [
            "otherUid": me,
            "status": FriendStatus.requested.rawValue,
            "requestedBy": me, // quien la inició (yo)
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        let batch = db.batch()
        batch.setData(payloadMine, forDocument: friendDoc(me, other), merge: true)
        batch.setData(payloadOther, forDocument: friendDoc(other, me), merge: true)
        try await batch.commit()
    }

    /// Aceptar: deja ambos lados en status=accepted
    func acceptRequest(myUid: String, from otherUid: String) async throws {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        let now = Date()
        let payloadMine: [String: Any] = [
            "otherUid": other,
            "status": FriendStatus.accepted.rawValue,
            "updatedAt": Timestamp(date: now)
        ]

        let payloadOther: [String: Any] = [
            "otherUid": me,
            "status": FriendStatus.accepted.rawValue,
            "updatedAt": Timestamp(date: now)
        ]

        let batch = db.batch()
        batch.setData(payloadMine, forDocument: friendDoc(me, other), merge: true)
        batch.setData(payloadOther, forDocument: friendDoc(other, me), merge: true)
        try await batch.commit()
    }

    /// Rechazar/cancelar/eliminar: borra ambos docs
    func removeRelation(myUid: String, otherUid: String) async throws {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        let batch = db.batch()
        batch.deleteDocument(friendDoc(me, other))
        batch.deleteDocument(friendDoc(other, me))
        try await batch.commit()
    }

    /// Bloquear: status=blocked solo en MI lado
    func block(myUid: String, otherUid: String) async throws {
        let me = myUid.trimmingCharacters(in: .whitespacesAndNewlines)
        let other = otherUid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !me.isEmpty, !other.isEmpty, me != other else { return }

        let now = Date()
        try await friendDoc(me, other).setData([
            "otherUid": other,
            "status": FriendStatus.blocked.rawValue,
            "requestedBy": me,
            "updatedAt": Timestamp(date: now),
            "createdAt": Timestamp(date: now)
        ], merge: true)
    }
}

// MARK: - ✅ Compatibility aliases (para VMs viejos)

extension FriendsRepository {

    /// Alias: antes algunos VMs llamaban listRelations
    func listRelations(myUid: String) async throws -> [FriendRelation] {
        try await fetchRelations(myUid: myUid)
    }

    /// Alias: antes algunos VMs llamaban fetchMyRelations
    func fetchMyRelations(myUid: String) async throws -> [FriendRelation] {
        try await fetchRelations(myUid: myUid)
    }

    /// Alias: sendFriendRequest(myUid:to:)
    func sendFriendRequest(myUid: String, to otherUid: String) async throws {
        try await sendRequest(myUid: myUid, to: otherUid)
    }

    /// Alias: sendFriendRequest(myUid:otherUid:)
    func sendFriendRequest(myUid: String, otherUid: String) async throws {
        try await sendRequest(myUid: myUid, to: otherUid)
    }

    /// Alias: acceptFriendRequest(myUid:otherUid:)
    func acceptFriendRequest(myUid: String, otherUid: String) async throws {
        try await acceptRequest(myUid: myUid, from: otherUid)
    }

    /// Alias: acceptFriendRequest(myUid:from:)
    func acceptFriendRequest(myUid: String, from otherUid: String) async throws {
        try await acceptRequest(myUid: myUid, from: otherUid)
    }

    /// Alias: blockUser
    func blockUser(myUid: String, otherUid: String) async throws {
        try await block(myUid: myUid, otherUid: otherUid)
    }
}
