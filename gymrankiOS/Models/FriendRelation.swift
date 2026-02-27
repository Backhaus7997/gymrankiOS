//
//  FriendRelation.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 26/02/2026.
//

import Foundation
import FirebaseFirestore

enum FriendStatus: String, Codable {
    case requested
    case accepted
    case blocked
}

struct FriendRelation: Identifiable, Codable, Equatable {

    var id: String { otherUid }
    var otherUid: String

    var status: FriendStatus
    var requestedBy: String?

    var createdAt: Date?
    var updatedAt: Date?

    init(
        otherUid: String,
        status: FriendStatus,
        requestedBy: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.otherUid = otherUid
        self.status = status
        self.requestedBy = requestedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Firestore mapping helpers

extension FriendRelation {

        static func fromFirestore(docId: String, data: [String: Any]) -> FriendRelation {
        let statusRaw = (data["status"] as? String) ?? FriendStatus.requested.rawValue
        let status = FriendStatus(rawValue: statusRaw) ?? .requested

        let requestedBy = data["requestedBy"] as? String

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()

        return FriendRelation(
            otherUid: (data["otherUid"] as? String) ?? docId,
            status: status,
            requestedBy: requestedBy,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Payload para guardar en Firestore.
    /// (otherUid va implícito en el documentID, pero lo dejamos opcional por si querés)
    func toFirestorePayload(includeOtherUidField: Bool = false) -> [String: Any] {
        var out: [String: Any] = [
            "status": status.rawValue,
            "requestedBy": requestedBy as Any,
            "createdAt": createdAt.map { Timestamp(date: $0) } as Any,
            "updatedAt": updatedAt.map { Timestamp(date: $0) } as Any
        ]

        if includeOtherUidField {
            out["otherUid"] = otherUid
        }
        return out
    }
}
