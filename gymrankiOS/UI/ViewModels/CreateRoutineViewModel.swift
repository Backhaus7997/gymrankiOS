//
//  CreateRoutineViewModel.swift
//  gymrankiOS
//

import Foundation

@MainActor
final class CreateRoutineViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var description: String = ""

    @Published var exercises: [RoutineExercise] = [
        RoutineExercise()
    ]

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var didSave: Bool = false

    private let repo = RoutineRepository()

    func addExercise() {
        exercises.append(RoutineExercise())
    }

    func removeExercise(id: String) {
        exercises.removeAll { $0.id == id }
        if exercises.isEmpty {
            exercises.append(RoutineExercise())
        }
    }

    /// Guarda la rutina asociada al usuario
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

        // Limpieza: nombre trim + filtrar vacíos
        var cleanedExercises: [RoutineExercise] = exercises
            .map { ex in
                var copy = ex
                copy.name = ex.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return copy
            }
            .filter { !$0.name.isEmpty }

        if cleanedExercises.isEmpty {
            errorMessage = "Agregá al menos un ejercicio con nombre."
            return
        }

        // Validación y normalización
        for i in cleanedExercises.indices {
            let ex = cleanedExercises[i]

            if ex.sets < 1 || ex.reps < 1 {
                errorMessage = "Sets y reps deben ser al menos 1 (ejercicio #\(i + 1))."
                return
            }

            if ex.usesBodyweight {
                cleanedExercises[i].weightKg = nil
            } else {
                if let w = ex.weightKg, w < 0 {
                    errorMessage = "El peso no puede ser negativo (ejercicio #\(i + 1))."
                    return
                }
            }
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let routine = WorkoutRoutine(
                id: UUID().uuidString,
                userId: uid,
                title: cleanTitle,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : description.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: nil,
                updatedAt: nil,
                exercises: cleanedExercises
            )

            try await repo.createRoutine(routine)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
