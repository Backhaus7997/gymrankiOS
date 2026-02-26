import Foundation

struct SetsPerMuscleCalculator {

    static func currentWeekInterval(from date: Date = Date(), calendar: Calendar = .current) -> DateInterval {
        var cal = calendar
        cal.firstWeekday = 2 // Lunes

        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let start = cal.date(from: components) ?? cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 7, to: start) ?? date

        return DateInterval(start: start, end: end)
    }

    static func setsByMuscle(
        routines: [WorkoutRoutine],
        in interval: DateInterval = currentWeekInterval()
    ) -> [RoutineMuscle: Int] {

        var acc: [RoutineMuscle: Int] = [:]

        for routine in routines {

            // ✅ En tu BD: updatedAt (timestamp). Asumo que en tu model es Date?
            guard let date = routine.updatedAt else { continue }
            guard interval.contains(date) else { continue }

            for ex in routine.exercises {

                if let main = ExercisesCatalogLookup.muscle(forExerciseName: ex.name) {
                    acc[main, default: 0] += ex.sets
                    continue
                }

                if ex.muscles.count == 1, let m = RoutineMuscle(rawValue: ex.muscles[0]) {
                    acc[m, default: 0] += ex.sets
                } else {
                }
            }
        }

        return acc
    }
}
