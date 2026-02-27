//
//  FeedWorkoutItem.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 26/02/2026.
//

import Foundation
import FirebaseFirestore

struct FeedWorkoutItem: Identifiable, Equatable {
    let id: String

    // owner
    let ownerUid: String
    let authorUsername: String
    let authorAvatarUrl: String?
    let authorLevel: Int
    let authorSubtitle: String?
    let authorFeedVisibility: String

    // workout
    let title: String
    let muscles: [String]
    let intensity: String?
    let durationMin: Int?
    let createdAt: Date?

    // resumen para la card (2-3)
    let exercisesSummary: [FeedWorkoutExercise]

    // meta
    let timeAgo: String
    let visibilityLabel: String
}

struct FeedWorkoutExercise: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let reps: String
    let weight: String
}

extension FeedWorkoutItem {

    static func fromFirestore(doc: QueryDocumentSnapshot) -> FeedWorkoutItem? {
        let d = doc.data()

        let title = (d["title"] as? String) ?? "Entrenamiento"
        let authorFeedVisibility = (d["authorFeedVisibility"] as? String) ?? "PUBLIC"

        let authorUsername = (d["authorUsername"] as? String)
            ?? (d["username"] as? String)
            ?? "user"

        let authorAvatarUrl = (d["authorAvatarUrl"] as? String)
            ?? (d["avatarUrl"] as? String)

        let authorLevel = (d["authorLevel"] as? Int) ?? (d["level"] as? Int) ?? 1
        let authorSubtitle = (d["authorSubtitle"] as? String) ?? (d["subtitle"] as? String)

        // createdAt (✅ tu doc lo tiene)
        let createdAt = (d["createdAt"] as? Timestamp)?.dateValue()

        let intensity = d["intensity"] as? String
        let durationMin = d["durationMin"] as? Int

        // muscles: en tus docs no está top-level; lo inferimos desde exercises.muscles
        var muscles: [String] = []
        if let exArr = d["exercises"] as? [[String: Any]] {
            let inferred = exArr.compactMap { ($0["muscles"] as? [String]) }.flatMap { $0 }
            muscles = Array(Set(inferred)).sorted()
        }

        // exercisesSummary: se arma desde "exercises" (✅ tu doc lo tiene)
        let summary = buildSummary(fromExercisesField: d["exercises"])

        // owner uid desde path "users/<uid>/routines/<id>"
        let comps = doc.reference.path.split(separator: "/")
        let ownerUid = comps.count >= 2 ? String(comps[1]) : ""

        let timeAgo = Self.timeAgo(from: createdAt)
        let visibilityLabel = labelForVisibility(authorFeedVisibility)

        return FeedWorkoutItem(
            id: doc.documentID,
            ownerUid: ownerUid,
            authorUsername: authorUsername,
            authorAvatarUrl: authorAvatarUrl,
            authorLevel: authorLevel,
            authorSubtitle: authorSubtitle,
            authorFeedVisibility: authorFeedVisibility,
            title: title,
            muscles: muscles,
            intensity: intensity,
            durationMin: durationMin,
            createdAt: createdAt,
            exercisesSummary: summary,
            timeAgo: timeAgo,
            visibilityLabel: visibilityLabel
        )
    }

    private static func buildSummary(fromExercisesField field: Any?) -> [FeedWorkoutExercise] {
        guard let arr = field as? [[String: Any]] else { return [] }

        return arr.prefix(3).compactMap { ex in
            let name = (ex["name"] as? String) ?? "-"
            let repsInt = (ex["reps"] as? Int) ?? 0
            let setsInt = (ex["sets"] as? Int) ?? 0 // por si después lo querés mostrar
            _ = setsInt

            let usesBodyweight = (ex["usesBodyweight"] as? Bool) ?? false
            let weightKg = (ex["weightKg"] as? Int)

            let repsStr: String = repsInt > 0 ? "\(repsInt)" : "—"
            let weightStr: String
            if usesBodyweight {
                weightStr = "BW"
            } else if let w = weightKg {
                weightStr = "\(w) kg"
            } else {
                weightStr = "—"
            }

            return FeedWorkoutExercise(name: name, reps: repsStr, weight: weightStr)
        }
    }

    private static func labelForVisibility(_ raw: String) -> String {
        switch raw.uppercased() {
        case "PUBLIC": return "Público"
        case "FRIENDS_ONLY": return "Amigos"
        case "PRIVATE": return "Privado"
        default: return "Público"
        }
    }

    static func timeAgo(from date: Date?) -> String {
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
