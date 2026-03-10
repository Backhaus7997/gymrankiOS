//
//  Bet.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

enum UserBetStatus {
    static let active = "ACTIVE"
    static let completed = "COMPLETED"
    static let failed = "FAILED"
    static let cancelled = "CANCELLED"
}

enum FSNum {
    static func int(_ any: Any?) -> Int {
        if let v = any as? Int { return v }
        if let v = any as? Int64 { return Int(v) }
        if let v = any as? Double { return Int(v) }
        if let v = any as? NSNumber { return v.intValue }
        return 0
    }

    static func int64(_ any: Any?) -> Int64 {
        if let v = any as? Int64 { return v }
        if let v = any as? Int { return Int64(v) }
        if let v = any as? Double { return Int64(v) }
        if let v = any as? NSNumber { return v.int64Value }
        return 0
    }
}

struct BetTask: Hashable {
    let name: String
    let description: String
    let target: Int
    let unit: String   // "reps" | "min"
}

struct BetTemplate: Hashable, Identifiable {
    let id: String
    let title: String
    let difficulty: String   // "EASY" | "MEDIUM" | "HARD"
    let focus: String        // "upper" | "lower" | "abs" | "cardio"
    let durationType: String // "daily" | "short"
    let timeLimitSeconds: Int
    let points: Int
    let isActive: Bool
    let tasks: [BetTask]

    var difficultyDisplay: String {
        switch difficulty {
        case "EASY": return "Fácil"
        case "MEDIUM": return "Medio"
        case "HARD": return "Difícil"
        default: return difficulty
        }
    }

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }

        let title = data["title"] as? String ?? ""
        let difficulty = data["difficulty"] as? String ?? ""
        let focus = data["focus"] as? String ?? ""
        let durationType = data["durationType"] as? String ?? ""
        let timeLimitSeconds = FSNum.int(data["timeLimitSeconds"])
        let points = FSNum.int(data["points"])
        let isActive = data["isActive"] as? Bool ?? false

        guard !title.isEmpty,
              !difficulty.isEmpty,
              !focus.isEmpty,
              !durationType.isEmpty,
              timeLimitSeconds > 0 else { return nil }

        let rawTasks = data["tasks"] as? [[String: Any]] ?? []
        let tasks: [BetTask] = rawTasks.compactMap { t in
            let name = t["name"] as? String ?? ""
            let desc = t["description"] as? String ?? ""
            let unit = t["unit"] as? String ?? ""
            let target = FSNum.int(t["target"])
            guard !name.isEmpty, !desc.isEmpty, !unit.isEmpty, target > 0 else { return nil }
            return BetTask(name: name, description: desc, target: target, unit: unit)
        }

        self.id = doc.documentID
        self.title = title
        self.difficulty = difficulty
        self.focus = focus
        self.durationType = durationType
        self.timeLimitSeconds = timeLimitSeconds
        self.points = points
        self.isActive = isActive
        self.tasks = tasks
    }
}

struct UserBet: Hashable, Identifiable {
    let id: String              // docId (uid_templateId)
    let uid: String
    let templateId: String
    let status: String          // ACTIVE/COMPLETED/FAILED/CANCELLED
    let createdAt: Int64        // ms epoch
    let startedAt: Int64        // ms epoch
    let expiresAt: Int64        // ms epoch
    let progress: [Int]         // mismos índices que template.tasks
}
