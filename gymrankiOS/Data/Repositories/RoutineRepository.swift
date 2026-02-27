//
//  RoutineRepository.swift
//  gymrankiOS
//

import Foundation
import FirebaseFirestore

final class RoutineRepository {

    private let db = Firestore.firestore()

    /// Crea una rutina en: users/{uid}/routines/{routineId}
    /// y agrega authorFeedVisibility leyendo users/{uid}.feedVisibility
    func createRoutine(_ routine: WorkoutRoutine) async throws {
        let uid = routine.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { throw NSError(domain: "RoutineRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "userId vacío"]) }

        // 1) leer visibilidad del user (snapshot)
        let userDoc = try await db.collection("users").document(uid).getDocument()
        let feedVisibility = (userDoc.data()?["feedVisibility"] as? String) ?? "PUBLIC"

        // 2) armar payload
        let now = Date()
        let createdAt = routine.createdAt ?? now
        let updatedAt = routine.updatedAt ?? now

        let exercisesPayload: [[String: Any]] = routine.exercises.map { ex in
            return [
                "id": ex.id,
                "exerciseId": ex.exerciseId as Any,
                "name": ex.name,
                "sets": ex.sets,
                "reps": ex.reps,
                "usesBodyweight": ex.usesBodyweight,
                "weightKg": ex.weightKg as Any,
                "weekday": ex.weekday,
                "muscles": ex.muscles
            ]
        }

        let data: [String: Any] = [
            "id": routine.id,
            "userId": uid,
            "title": routine.title,
            "description": routine.description as Any,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "authorFeedVisibility": feedVisibility, // ✅ acá queda “creado”
            "exercises": exercisesPayload
        ]

        // 3) guardar
        try await db.collection("users")
            .document(uid)
            .collection("routines")
            .document(routine.id)
            .setData(data, merge: true)
    }

    // (Opcional) Listar rutinas del usuario
    func fetchRoutines(userId: String) async throws -> [WorkoutRoutine] {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return [] }

        let snap = try await db.collection("users")
            .document(uid)
            .collection("routines")
            .order(by: "updatedAt", descending: true)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let d = doc.data()

            let createdAt = (d["createdAt"] as? Timestamp)?.dateValue()
            let updatedAt = (d["updatedAt"] as? Timestamp)?.dateValue()

            let exercises: [RoutineExercise] = (d["exercises"] as? [[String: Any]] ?? []).map { ex in
                RoutineExercise(
                    id: (ex["id"] as? String) ?? UUID().uuidString,
                    exerciseId: ex["exerciseId"] as? String,
                    name: (ex["name"] as? String) ?? "",
                    sets: (ex["sets"] as? Int) ?? 3,
                    reps: (ex["reps"] as? Int) ?? 10,
                    usesBodyweight: (ex["usesBodyweight"] as? Bool) ?? false,
                    weightKg: ex["weightKg"] as? Int,
                    weekday: (ex["weekday"] as? Int) ?? 2,
                    muscles: (ex["muscles"] as? [String]) ?? []
                )
            }

            return WorkoutRoutine(
                id: (d["id"] as? String) ?? doc.documentID,
                userId: (d["userId"] as? String) ?? uid,
                title: (d["title"] as? String) ?? "Rutina",
                description: d["description"] as? String,
                createdAt: createdAt,
                updatedAt: updatedAt,
                exercises: exercises,
                authorFeedVisibility: d["authorFeedVisibility"] as? String
            )
        }
    }

    // (Opcional) Borrar rutina
    func deleteRoutine(userId: String, routineId: String) async throws {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        let rid = routineId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty, !rid.isEmpty else { return }

        try await db.collection("users")
            .document(uid)
            .collection("routines")
            .document(rid)
            .delete()
    }
}
