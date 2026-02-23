import Foundation

// MARK: - Models (workout history)

struct WorkoutLog: Identifiable {
    var id: String
    var performedAt: Date
    var exercises: [LoggedExercise]
}

struct LoggedExercise: Identifiable {
    var id: String
    var name: String
    var sets: [LoggedSet]
}

struct LoggedSet: Identifiable {
    var id: String
    var reps: Int
    var weightKg: Double
    var usesBodyweight: Bool
}

// MARK: - Normalize names (to match catalog vs db)

enum NameNormalizer {
    static func key(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: [.diacriticInsensitive], locale: .current)
    }
}
