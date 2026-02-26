import Foundation
import FirebaseFirestore

// MARK: - Template

struct WorkoutTemplate: Identifiable {
    let id: String

    let title: String
    let description: String
    let frequencyPerWeek: Int
    let goalTags: [String]
    let isPro: Bool
    let level: String
    let visibility: String
    let weeks: Int

    let createdAt: Timestamp?
    let updatedAt: Timestamp?
}

// MARK: - Days

struct WorkoutTemplateDay: Identifiable {
    let id: String
    let title: String
    let description: String
    let weekday: Int
    let order: Int?
    let exercises: [WorkoutTemplateExercise]
}

struct WorkoutTemplateExercise: Identifiable {
    var id: String { "\(name)-\(sets)-\(reps)-\(order ?? 0)" }

    let name: String
    let reps: Int
    let sets: Int
    let usesBodyweight: Bool
    let weightKg: Double
    let order: Int?
    let weekday: Int?
}
