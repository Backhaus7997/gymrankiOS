import SwiftUI

@MainActor
final class SetsPerMuscleViewModel: ObservableObject {
    @Published var stats: [MuscleSetStat] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let repo = RoutineRepository()

    func load(userId: String) async {
        guard !userId.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let routines = try await repo.fetchRoutines(userId: userId)
            let dict = SetsPerMuscleCalculator.setsByMuscle(routines: routines)

            let all = RoutineMuscle.allCases.map { m in
                MuscleSetStat(name: m.rawValue, sets: dict[m, default: 0])
            }

            self.stats = all.sorted {
                if $0.sets != $1.sets { return $0.sets > $1.sets }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
