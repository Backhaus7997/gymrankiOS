//
//  Mission.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 02/03/2026.
//

import Foundation
import FirebaseFirestore

struct MissionTemplate: Identifiable, Hashable {
    let id: String

    let title: String
    let subtitle: String
    let level: String
    let points: Int
    let tags: [String]
    let isActive: Bool
    let durationDays: Int

    // opcional para misiones custom/medibles
    let goalWorkouts: Int?

    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        self.id = document.documentID

        self.title = data["title"] as? String ?? ""
        self.subtitle = data["subtitle"] as? String ?? ""
        self.level = data["level"] as? String ?? ""
        self.points = Self.intValue(data["points"])
        self.tags = data["tags"] as? [String] ?? []
        self.isActive = data["isActive"] as? Bool ?? true

        // missions: usamos durationDays (sin typo). Igual tolero "dirationDays" por las dudas.
        let d1 = Self.intValue(data["durationDays"])
        let d2 = Self.intValue(data["dirationDays"])
        self.durationDays = d1 != 0 ? d1 : d2

        self.goalWorkouts = Self.intValueOptional(data["goalWorkouts"])

        self.createdAt = data["createdAt"] as? Timestamp
        self.updatedAt = data["updatedAt"] as? Timestamp
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
        case "facil", "fácil": return "Fácil"
        case "dificil", "difícil": return "Difícil"
        default:
            return level.prefix(1).uppercased() + level.dropFirst()
        }
    }

    private static func intValue(_ any: Any?) -> Int {
        if let v = any as? Int { return v }
        if let v = any as? Int64 { return Int(v) }
        if let v = any as? Double { return Int(v) }
        if let v = any as? NSNumber { return v.intValue }
        return 0
    }

    private static func intValueOptional(_ any: Any?) -> Int? {
        let v = intValue(any)
        return v == 0 ? nil : v
    }
}

struct UserMission: Identifiable, Hashable {
    let id: String

    let uid: String
    let templateId: String
    let status: String

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

enum UserMissionStatus {
    static let active = "ACTIVE"
    static let completed = "COMPLETED"
    static let cancelled = "CANCELLED"
}
