//
//  Routine+RecoverySchedule.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import Foundation

extension WorkoutRoutine {
    func recoverySchedule() -> MuscleRecoveryEngine.Schedule {
        var dict: [String: Set<Int>] = [:]

        for ex in exercises {
            guard ex.weekday >= 1 && ex.weekday <= 7 else { continue }
            for m in ex.muscles where !m.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                dict[m, default: []].insert(ex.weekday)
            }
        }

        return MuscleRecoveryEngine.Schedule(weekdaysByMuscle: dict)
    }
}
