import Foundation

enum ExercisesCatalogLookup {

    static let byExerciseName: [String: RoutineMuscle] = {
        var dict: [String: RoutineMuscle] = [:]

        for entry in ExercisesCatalogData.catalog {
            guard let muscle = RoutineMuscle(rawValue: entry.muscle) else { continue }

            for exName in entry.exercises {
                let key = normalize(exName)


                if dict[key] == nil {
                    dict[key] = muscle
                }
            }
        }

        return dict
    }()

    static func muscle(forExerciseName name: String) -> RoutineMuscle? {
        byExerciseName[normalize(name)]
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
