//
//  MuscleRecoveryEngine.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 23/02/2026.
//

import Foundation

// MARK: - Models

struct MuscleRecovery: Identifiable, Hashable {
    let id = UUID()
    let muscle: String
    let percent: Double   // 0...1
    let nextDate: Date
}

// MARK: - Engine

enum MuscleRecoveryEngine {

    /// weekday: 1=Sunday ... 7=Saturday (Calendar.current)
    struct Schedule {
        /// Ej: "Pecho" -> [2, 5] (lunes y jueves)
        let weekdaysByMuscle: [String: Set<Int>]
    }

    static func computeAll(
        schedule: Schedule,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleRecovery] {

        schedule.weekdaysByMuscle.map { (muscle, weekdays) in
            let next = nextOccurrence(from: now, weekdays: weekdays, calendar: calendar)
            let prev = previousOccurrence(before: next, weekdays: weekdays, calendar: calendar)

            // Si por alguna razón no podemos sacar intervalo, asumimos 7 días.
            let totalDays = max(1, daysBetween(prev, next, calendar: calendar))
            let remainingDays = max(0, daysBetween(now, next, calendar: calendar))

            // Día que toca entrenar -> 100%
            let pct: Double
            if isSameDay(now, next, calendar: calendar) {
                pct = 1.0
            } else {
                pct = 1.0 - (Double(remainingDays) / Double(totalDays))
            }

            return MuscleRecovery(
                muscle: muscle,
                percent: clamp(pct, 0, 1),
                nextDate: next
            )
        }
        .sorted { $0.percent > $1.percent }
    }

    static func top(
        schedule: Schedule,
        limit: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [MuscleRecovery] {
        Array(computeAll(schedule: schedule, now: now, calendar: calendar).prefix(limit))
    }

    // MARK: - Date helpers

    private static func nextOccurrence(from now: Date, weekdays: Set<Int>, calendar: Calendar) -> Date {
        // Si hoy es uno de los weekdays => next = hoy (para que sea 100%)
        let todayWeekday = calendar.component(.weekday, from: now)
        if weekdays.contains(todayWeekday) {
            return calendar.startOfDay(for: now)
        }

        // Busco el próximo día (1..14 días para cubrir semanas)
        for add in 1...14 {
            if let d = calendar.date(byAdding: .day, value: add, to: now) {
                let wd = calendar.component(.weekday, from: d)
                if weekdays.contains(wd) {
                    return calendar.startOfDay(for: d)
                }
            }
        }

        // Fallback: +7
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: 7, to: now) ?? now)
    }

    private static func previousOccurrence(before next: Date, weekdays: Set<Int>, calendar: Calendar) -> Date {
        // Busco hacia atrás
        for sub in 1...14 {
            if let d = calendar.date(byAdding: .day, value: -sub, to: next) {
                let wd = calendar.component(.weekday, from: d)
                if weekdays.contains(wd) {
                    return calendar.startOfDay(for: d)
                }
            }
        }
        // Fallback: -7
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: next) ?? next)
    }

    private static func daysBetween(_ a: Date, _ b: Date, calendar: Calendar) -> Int {
        let startA = calendar.startOfDay(for: a)
        let startB = calendar.startOfDay(for: b)
        return calendar.dateComponents([.day], from: startA, to: startB).day ?? 0
    }

    private static func isSameDay(_ a: Date, _ b: Date, calendar: Calendar) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    private static func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(x, lo), hi)
    }
}
