//
//  Challenge.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

// MARK: - Challenge Template (challenge_templates)

struct ChallengeTemplate: Identifiable, Hashable {
    let id: String

    let title: String
    let subtitle: String
    let level: String
    let points: Int
    let tags: [String]
    let isActive: Bool

    // En tu Firestore está como "dirationDays" (typo)
    let durationDays: Int

    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    // Opcionales por si los agregás después
    let imageName: String?
    let isHot: Bool?

    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID

        self.title = data["title"] as? String ?? ""
        self.subtitle = data["subtitle"] as? String ?? ""
        self.level = data["level"] as? String ?? ""
        self.points = Self.intValue(data["points"])
        self.tags = data["tags"] as? [String] ?? []
        self.isActive = data["isActive"] as? Bool ?? true

        // soporta durationDays o el typo dirationDays
        let d1 = Self.intValue(data["durationDays"])
        let d2 = Self.intValue(data["dirationDays"])
        self.durationDays = d1 != 0 ? d1 : d2

        self.createdAt = data["createdAt"] as? Timestamp
        self.updatedAt = data["updatedAt"] as? Timestamp

        self.imageName = data["imageName"] as? String
        self.isHot = data["isHot"] as? Bool
    }

    var durationText: String { "\(durationDays) DÍAS" }

    var levelDisplay: String {
        let raw = level.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch raw {
        case "medio": return "Intermedio"
        case "intermedio": return "Intermedio"
        case "principiante": return "Principiante"
        case "avanzado": return "Avanzado"
        case "experto": return "Experto"
        default:
            return level.prefix(1).uppercased() + level.dropFirst()
        }
    }

    var hotDisplay: Bool {
        if let isHot { return isHot }
        if points >= 150 { return true }
        return tags.map { $0.lowercased() }.contains(where: { $0.contains("hard") })
    }

    private static func intValue(_ any: Any?) -> Int {
        if let v = any as? Int { return v }
        if let v = any as? Int64 { return Int(v) }
        if let v = any as? Double { return Int(v) }
        if let v = any as? NSNumber { return v.intValue }
        return 0
    }
}

// MARK: - User Challenge (user_challenges)

struct UserChallenge: Identifiable, Hashable {
    let id: String

    let uid: String
    let templateId: String
    let status: String

    // en tu DB son ms desde epoch
    let createdAt: Int64
    let startedAt: Int64
    let updatedAt: Int64

    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID

        self.uid = data["uid"] as? String ?? ""
        self.templateId = data["templateId"] as? String ?? ""
        self.status = data["status"] as? String ?? ""

        self.createdAt = Self.int64Value(data["createdAt"])
        self.startedAt = Self.int64Value(data["startedAt"])
        self.updatedAt = Self.int64Value(data["updatedAt"])
    }

    var startedDate: Date { Date(timeIntervalSince1970: TimeInterval(startedAt) / 1000.0) }

    private static func int64Value(_ any: Any?) -> Int64 {
        if let v = any as? Int64 { return v }
        if let v = any as? Int { return Int64(v) }
        if let v = any as? Double { return Int64(v) }
        if let v = any as? NSNumber { return v.int64Value }
        return 0
    }
}

enum UserChallengeStatus {
    static let active = "ACTIVE"
    static let completed = "COMPLETED"
    static let cancelled = "CANCELLED"
}
