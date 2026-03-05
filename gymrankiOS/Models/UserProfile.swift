//
//  UserProfile.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

enum FeedVisibility: String, Codable {
    case `public` = "PUBLIC"
    case friendsOnly = "FRIENDS_ONLY"
    case `private` = "PRIVATE"
}

struct UserProfile: Identifiable, Codable, Equatable {
    var id: String { uid }

    var uid: String
    var username: String?
    var fullName: String?
    var avatarUrl: String?

    /// Nivel (si lo usás). Default 1
    var level: Int

    /// Legacy (lo dejamos por compatibilidad)
    var score: Int

    /// NUEVOS: puntajes por período
    var scoreWeekly: Int
    var scoreMonthly: Int
    var scoreAllTime: Int

    /// Keys para saber si hay que resetear al cambiar semana/mes
    var scoreWeeklyKey: String?
    var scoreMonthlyKey: String?

    var subtitle: String?
    var feedVisibility: FeedVisibility
    var gymId: String?
    var gymNameCache: String?
    var gymCityCache: String?
    var experience: String?
    var gender: String?
    var createdAt: Date?
    var updatedAt: Date?

    init(
        uid: String,
        username: String? = nil,
        fullName: String? = nil,
        avatarUrl: String? = nil,
        level: Int = 1,

        // legacy
        score: Int = 0,

        // nuevos
        scoreWeekly: Int = 0,
        scoreMonthly: Int = 0,
        scoreAllTime: Int = 0,
        scoreWeeklyKey: String? = nil,
        scoreMonthlyKey: String? = nil,

        subtitle: String? = nil,
        feedVisibility: FeedVisibility = .public,
        gymId: String? = nil,
        gymNameCache: String? = nil,
        gymCityCache: String? = nil,
        experience: String? = nil,
        gender: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.uid = uid
        self.username = username
        self.fullName = fullName
        self.avatarUrl = avatarUrl
        self.level = level

        self.score = score

        self.scoreWeekly = scoreWeekly
        self.scoreMonthly = scoreMonthly
        self.scoreAllTime = scoreAllTime
        self.scoreWeeklyKey = scoreWeeklyKey
        self.scoreMonthlyKey = scoreMonthlyKey

        self.subtitle = subtitle
        self.feedVisibility = feedVisibility
        self.gymId = gymId
        self.gymNameCache = gymNameCache
        self.gymCityCache = gymCityCache
        self.experience = experience
        self.gender = gender
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Firestore mapping helpers

extension UserProfile {

    static func fromFirestore(docId: String, data: [String: Any]) -> UserProfile {

        // feedVisibility
        let visRaw = (data["feedVisibility"] as? String) ?? FeedVisibility.public.rawValue
        let vis = FeedVisibility(rawValue: visRaw) ?? .public

        // campos comunes
        let fullName = data["fullName"] as? String
        let email = data["email"] as? String

        let username = (data["username"] as? String)
            ?? (data["handle"] as? String)
            ?? email?.split(separator: "@").first.map(String.init)

        let level = (data["level"] as? Int) ?? 1

        // legacy
        let legacyScore = (data["score"] as? Int) ?? 0

        // nuevos (fallback al legacy)
        let scoreWeekly = (data["scoreWeekly"] as? Int) ?? legacyScore
        let scoreMonthly = (data["scoreMonthly"] as? Int) ?? legacyScore
        let scoreAllTime = (data["scoreAllTime"] as? Int) ?? legacyScore

        let scoreWeeklyKey = data["scoreWeeklyKey"] as? String
        let scoreMonthlyKey = data["scoreMonthlyKey"] as? String

        let subtitle = (data["subtitle"] as? String) ?? (data["experience"] as? String)

        let avatarUrl = (data["avatarUrl"] as? String) ?? (data["photoUrl"] as? String)

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()

        return UserProfile(
            uid: (data["uid"] as? String) ?? docId,
            username: username,
            fullName: fullName,
            avatarUrl: avatarUrl,
            level: level,

            score: legacyScore,

            scoreWeekly: scoreWeekly,
            scoreMonthly: scoreMonthly,
            scoreAllTime: scoreAllTime,
            scoreWeeklyKey: scoreWeeklyKey,
            scoreMonthlyKey: scoreMonthlyKey,

            subtitle: subtitle,
            feedVisibility: vis,
            gymId: data["gymId"] as? String,
            gymNameCache: data["gymNameCache"] as? String,
            gymCityCache: data["gymCityCache"] as? String,
            experience: data["experience"] as? String,
            gender: data["gender"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Texto para mostrar en UI como nombre principal
    var displayName: String {
        if let u = username, !u.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return u
        }
        if let n = fullName, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return n
        }
        return uid
    }

    /// Texto secundario debajo del nombre
    var displaySubtitle: String {
        if let s = subtitle, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        if let e = experience, !e.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return e
        }
        return "En progreso"
    }
}
