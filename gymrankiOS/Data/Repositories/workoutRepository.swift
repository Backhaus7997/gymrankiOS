//
//  workoutRepository.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class WorkoutsRepository {

    private let db = Firestore.firestore()

    func fetchUserWorkouts(limit: Int = 200) async throws -> [WorkoutLog] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }

        let snap = try await db
            .collection("users")
            .document(uid)
            .collection("workouts")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()

            let performedAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date.distantPast
            
            let exercisesRaw = data["exercises"] as? [[String: Any]] ?? []
            let exercises: [LoggedExercise] = exercisesRaw.compactMap { ex in
                let name = ex["name"] as? String ?? ""
                let exId = ex["id"] as? String ?? UUID().uuidString

                let setsRaw = ex["sets"] as? [[String: Any]] ?? []
                let sets: [LoggedSet] = setsRaw.compactMap { st in
                    let reps = st["reps"] as? Int ?? 0
                    let weight = st["weightKg"] as? Double ?? 0
                    let usesBW = st["usesBodyweight"] as? Bool ?? false
                    let setId = st["id"] as? String ?? UUID().uuidString
                    return LoggedSet(id: setId, reps: reps, weightKg: weight, usesBodyweight: usesBW)
                }

                return LoggedExercise(id: exId, name: name, sets: sets)
            }

            return WorkoutLog(id: doc.documentID, performedAt: performedAt, exercises: exercises)
        }
    }
}
