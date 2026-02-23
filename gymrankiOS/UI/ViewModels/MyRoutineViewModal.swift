import Foundation

@MainActor
final class MyRoutinesViewModel: ObservableObject {
    @Published var routines: [WorkoutRoutine] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let repo = RoutineRepository()
    private var lastLoadedUserId: String? = nil

    func load(userId: String) async {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else {
            routines = []
            errorMessage = nil
            isLoading = false
            lastLoadedUserId = nil
            return
        }

        // evita refetch redundante que genera flicker
        if isLoading { return }
        if lastLoadedUserId == uid, !routines.isEmpty { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            routines = try await repo.fetchRoutines(userId: uid)
            lastLoadedUserId = uid
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
