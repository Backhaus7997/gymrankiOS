//
//  CreateRoutineViewModel.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class CreateRoutineViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var description: String = ""

    /// Cada RoutineExercise debe tener id único para bindings/UI.
    @Published var exercises: [RoutineExercise] = [
        RoutineExercise(id: UUID().uuidString)
    ]

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didSave: Bool = false

    private let repo = RoutineRepository()

    init(source: RoutineDraftSource = .new) {
        hydrate(from: source)
    }

    func hydrate(from source: RoutineDraftSource) {
        didSave = false
        errorMessage = nil

        switch source {
        case .new:
            title = ""
            description = ""
            exercises = [RoutineExercise(id: UUID().uuidString)]

        case .fromTemplate(let routine):
            title = routine.title
            description = routine.description ?? ""

            let copiedExercises = routine.exercises.map { ex in
                RoutineExercise(
                    id: UUID().uuidString,   // nuevo id local
                    exerciseId: ex.exerciseId,
                    name: ex.name,
                    sets: ex.sets,
                    reps: ex.reps,
                    usesBodyweight: ex.usesBodyweight,
                    weightKg: ex.weightKg,
                    weekday: ex.weekday,
                    muscles: ex.muscles
                )
            }

            exercises = copiedExercises.isEmpty
                ? [RoutineExercise(id: UUID().uuidString)]
                : copiedExercises
        }
    }

    func addExercise() {
        exercises.append(RoutineExercise(id: UUID().uuidString))
    }

    func removeExercise(id: String) {
        exercises.removeAll { $0.id == id }

        if exercises.isEmpty {
            exercises = [RoutineExercise(id: UUID().uuidString)]
        }
    }

    /// Guarda SIEMPRE como rutina nueva.
    func save(userId: String) async {
        errorMessage = nil
        didSave = false

        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            errorMessage = "Tenés que iniciar sesión para guardar rutinas."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            errorMessage = "Poné un nombre para la rutina."
            return
        }

        var cleanedExercises: [RoutineExercise] = exercises
            .map { ex in
                var copy = ex
                copy.name = ex.name.trimmingCharacters(in: .whitespacesAndNewlines)

                if copy.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    copy.id = UUID().uuidString
                }

                return copy
            }
            .filter { !$0.name.isEmpty }

        if cleanedExercises.isEmpty {
            errorMessage = "Agregá al menos un ejercicio con nombre."
            return
        }

        for i in cleanedExercises.indices {
            let ex = cleanedExercises[i]

            if ex.sets < 1 || ex.reps < 1 {
                errorMessage = "Sets y reps deben ser al menos 1 (ejercicio #\(i + 1))."
                return
            }

            if ex.usesBodyweight {
                cleanedExercises[i].weightKg = nil
            } else if let w = ex.weightKg, w < 0 {
                errorMessage = "El peso no puede ser negativo (ejercicio #\(i + 1))."
                return
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let now = Date()

            let routine = WorkoutRoutine(
                id: UUID().uuidString, // siempre NUEVA
                userId: uid,
                title: cleanTitle,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : description.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: now,
                updatedAt: now,
                exercises: cleanedExercises,
                authorFeedVisibility: nil
            )

            try await repo.createRoutine(routine)
            didSave = true

            // reset del form después de guardar
            title = ""
            description = ""
            exercises = [RoutineExercise(id: UUID().uuidString)]

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
