import Foundation
import FirebaseFirestore

final class RoutineRepository {
    private let db = Firestore.firestore()

    func createRoutine(_ routine: WorkoutRoutine) async throws {
        let routineId = routine.id.isEmpty ? UUID().uuidString : routine.id

        let ref = db
            .collection("users")
            .document(routine.userId)
            .collection("routines")
            .document(routineId)

        let exercisesArray: [[String: Any]] = routine.exercises.map { ex in
            var dict: [String: Any] = [
                "id": ex.id,
                "name": ex.name,
                "sets": ex.sets,
                "reps": ex.reps,
                "usesBodyweight": ex.usesBodyweight
            ]
            dict["weightKg"] = ex.usesBodyweight ? NSNull() : (ex.weightKg as Any)
            return dict
        }

        let data: [String: Any] = [
            "userId": routine.userId,
            "title": routine.title,
            "description": routine.description as Any,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "exercises": exercisesArray
        ]

        // merge true evita pisar campos si algún día agregás más.
        try await ref.setData(data, merge: true)
    }

    func fetchRoutines(userId: String) async throws -> [WorkoutRoutine] {
        let snap = try await db
            .collection("users")
            .document(userId)
            .collection("routines")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snap.documents.map { doc in
            let data = doc.data()

            let title = data["title"] as? String ?? "Sin título"

            let description: String? = {
                let raw = data["description"]
                if raw is NSNull { return nil }
                return raw as? String
            }()

            let createdAtTS = data["createdAt"] as? Timestamp
            let updatedAtTS = data["updatedAt"] as? Timestamp

            let exercisesRaw = data["exercises"] as? [[String: Any]] ?? []
            let exercises: [RoutineExercise] = exercisesRaw.map { ex in
                RoutineExercise(
                    id: ex["id"] as? String ?? UUID().uuidString,
                    name: ex["name"] as? String ?? "",
                    sets: ex["sets"] as? Int ?? 3,
                    reps: ex["reps"] as? Int ?? 10,
                    usesBodyweight: ex["usesBodyweight"] as? Bool ?? false,
                    weightKg: ex["weightKg"] as? Int
                )
            }

            let storedUserId = data["userId"] as? String ?? userId

            return WorkoutRoutine(
                id: doc.documentID,
                userId: storedUserId,
                title: title,
                description: description,
                createdAt: createdAtTS?.dateValue(),
                updatedAt: updatedAtTS?.dateValue(),
                exercises: exercises
            )
        }
    }
}
