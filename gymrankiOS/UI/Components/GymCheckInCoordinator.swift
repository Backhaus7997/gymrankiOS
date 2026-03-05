import FirebaseFirestore
import Foundation

enum DayKey {
    static func todayArgentina() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Argentina/Cordoba") ?? .current

        let now = Date()
        let comps = cal.dateComponents([.year, .month, .day], from: now)

        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        let d = comps.day ?? 1

        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

@MainActor
final class GymCheckInCoordinator: ObservableObject {
    @Published var isPresented = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var today: String { DayKey.todayArgentina() }

    // ✅ Cada cuánto se puede volver a mostrar si está pendiente
    private let repromptInterval: TimeInterval = 10 * 60 // 10 minutos

    private func answeredKey(for uid: String) -> String { "gymCheckInAnsweredDay_\(uid)" }
    private func pendingKey(for uid: String) -> String  { "gymCheckInPendingDay_\(uid)" }
    private func lastShownKey(for uid: String) -> String { "gymCheckInLastShownAt_\(uid)" }

    private func getLastShown(uid: String) -> Date? {
        UserDefaults.standard.object(forKey: lastShownKey(for: uid)) as? Date
    }

    private func setLastShownNow(uid: String) {
        UserDefaults.standard.set(Date(), forKey: lastShownKey(for: uid))
    }

    func maybeShow(uid: String) async {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        // ✅ Gate por onboarding
        do {
            let doc = try await db.collection("users").document(clean).getDocument()
            let data = doc.data() ?? [:]
            let completed = (data["profileCompleted"] as? Bool) ?? false
            let gymId = (data["gymId"] as? String) ?? ""

            guard completed, !gymId.isEmpty else {
                isPresented = false
                return
            }
        } catch {
            isPresented = false
            return
        }

        // ✅ Si ya respondió hoy -> no mostrar
        if UserDefaults.standard.string(forKey: answeredKey(for: clean)) == today {
            isPresented = false
            return
        }

        let pending = UserDefaults.standard.string(forKey: pendingKey(for: clean))

        // ✅ Si está pendiente HOY:
        if pending == today {
            // gate de 10 minutos
            if let last = getLastShown(uid: clean),
               Date().timeIntervalSince(last) < repromptInterval {
                isPresented = false
                return
            }

            setLastShownNow(uid: clean)
            isPresented = true
            return
        }

        // ✅ Si no está pendiente ni respondido: crear pendiente y mostrar (1era vez)
        UserDefaults.standard.set(today, forKey: pendingKey(for: clean))
        setLastShownNow(uid: clean)
        isPresented = true
    }

    /// Se llamó “cerrar” sin elegir Sí/No.
    /// ✅ Queda pendiente y se re-muestra a los 10 min.
    func dismissWithoutAnswer(uid: String) {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { isPresented = false; return }

        // NO tocamos pending (queda)
        // Marcamos lastShown para que no spamee
        setLastShownNow(uid: clean)
        isPresented = false
    }

    func answerNo(uid: String) {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { isPresented = false; return }

        UserDefaults.standard.set(today, forKey: answeredKey(for: clean))
        UserDefaults.standard.removeObject(forKey: pendingKey(for: clean))
        UserDefaults.standard.removeObject(forKey: lastShownKey(for: clean))
        isPresented = false
    }

    func answerYes(uid: String, points: Int = 20) async {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { isPresented = false; return }

        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await UserRepository.shared.claimGymCheckIn(uid: clean, dayKey: today, points: points)

            UserDefaults.standard.set(today, forKey: answeredKey(for: clean))
            UserDefaults.standard.removeObject(forKey: pendingKey(for: clean))
            UserDefaults.standard.removeObject(forKey: lastShownKey(for: clean))

            isSubmitting = false
            isPresented = false
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}
