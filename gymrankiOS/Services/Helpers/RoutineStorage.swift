import Foundation
import FirebaseAuth

enum RoutineStorage {

    private static func keyForCurrentUser() -> String? {
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else { return nil }
        return "routine_plan_v1_\(uid)"
    }

    static func load() -> RoutinePlan? {
        guard let key = keyForCurrentUser() else { return nil }
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let plan = try? JSONDecoder().decode(RoutinePlan.self, from: data)
        else { return nil }
        return plan
    }

    static func save(_ plan: RoutinePlan) {
        guard let key = keyForCurrentUser() else { return }
        guard let data = try? JSONEncoder().encode(plan) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        guard let key = keyForCurrentUser() else { return }
        UserDefaults.standard.removeObject(forKey: key)
    }
}
