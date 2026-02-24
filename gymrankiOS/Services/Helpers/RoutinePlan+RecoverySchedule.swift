//
//  RoutinePlan+RecoverySchedule.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import Foundation

extension RoutinePlan {

    /// Convierte el plan semanal (Lun=1..Dom=7) a schedule del engine (Dom=1..Sab=7)
    func recoverySchedule() -> MuscleRecoveryEngine.Schedule {
        var dict: [String: Set<Int>] = [:]

        for (day, muscles) in byDay {
            let engineWeekday = day.toCalendarWeekday() // Dom=1..Sab=7

            for m in muscles {
                dict[m.rawValue, default: []].insert(engineWeekday)
            }
        }

        return MuscleRecoveryEngine.Schedule(weekdaysByMuscle: dict)
    }
}

private extension Weekday {
    /// Weekday (Lun=1..Dom=7) -> Calendar weekday (Dom=1..Sab=7)
    func toCalendarWeekday() -> Int {
        switch self {
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        case .sunday: return 1
        }
    }
}
