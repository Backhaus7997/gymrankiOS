import Foundation

struct WorkoutRoutine: Identifiable, Codable {
    var id: String
    var userId: String
    var title: String
    var description: String?
    var createdAt: Date?
    var updatedAt: Date?
    var exercises: [RoutineExercise]

    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        description: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        exercises: [RoutineExercise] = []
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.exercises = exercises
    }
}

struct RoutineExercise: Identifiable, Codable, Equatable {

    var id: String
    var exerciseId: String?
    var name: String
    var sets: Int
    var reps: Int
    var usesBodyweight: Bool
    var weightKg: Int?

    init(
        id: String = UUID().uuidString,
        exerciseId: String? = nil,
        name: String = "",
        sets: Int = 3,
        reps: Int = 10,
        usesBodyweight: Bool = false,
        weightKg: Int? = 60
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.name = name
        self.sets = sets
        self.reps = reps
        self.usesBodyweight = usesBodyweight
        self.weightKg = weightKg
    }
}
