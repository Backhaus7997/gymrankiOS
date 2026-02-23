//
//  ProgressVM.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class ProgressVM: ObservableObject {

    enum Metric: String, CaseIterable, Identifiable {
        case maxWeight = "Peso"
        case reps = "Reps"
        case volume = "Volumen"
        var id: String { rawValue }
    }

    struct ExercisePoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    @Published var isLoading = false
    @Published var routines: [WorkoutRoutine] = []
    @Published var errorMessage: String? = nil

    private let repo = RoutineRepository()

    // Para saber rápido qué ejercicios tienen datos en rutinas
    private(set) var performedExerciseKeys: Set<String> = []

    func load(userId: String) async {
        guard !userId.isEmpty else {
            routines = []
            performedExerciseKeys = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let data = try await repo.fetchRoutines(userId: userId)
            routines = data

            var keys: Set<String> = []
            for r in data {
                for ex in r.exercises {
                    keys.insert(NameNormalizer.key(ex.name))
                }
            }
            performedExerciseKeys = keys

            print("✅ ProgressVM loaded routines:", data.count, "unique exercises:", keys.count)
        } catch {
            errorMessage = error.localizedDescription
            routines = []
            performedExerciseKeys = []
            print("❌ ProgressVM load error:", error.localizedDescription)
        }
    }

    // Músculos del catálogo
    func muscles() -> [String] {
        ExercisesCatalogData.catalog.map { $0.muscle }
    }

    // Ejercicios del catálogo para un músculo
    func exercisesForMuscle(_ muscle: String) -> [String] {
        ExercisesCatalogData.catalog.first(where: { $0.muscle == muscle })?.exercises ?? []
    }

    func hasData(for exerciseName: String) -> Bool {
        performedExerciseKeys.contains(NameNormalizer.key(exerciseName))
    }

    func points(for exerciseName: String, metric: Metric) -> [ExercisePoint] {
        let key = NameNormalizer.key(exerciseName)
        var pts: [ExercisePoint] = []

        for r in routines {
            guard let ex = r.exercises.first(where: { NameNormalizer.key($0.name) == key }) else { continue }

            let reps = max(1, ex.reps ?? 0)
            let sets = max(1, ex.sets ?? 0)
            let weight = Double(ex.weightKg ?? 0)

            let value: Double
            switch metric {
            case .maxWeight:
                value = weight
            case .reps:
                value = Double(reps) // ✅ reps sin multiplicar por sets
            case .volume:
                value = Double(sets * reps) * weight
            }

            guard let date = r.createdAt else { continue }
            pts.append(.init(date: date, value: value))
        }

        return pts.sorted { $0.date < $1.date }
    }
}
