import Foundation
import FirebaseFirestore

enum ScoreResetter {
    static func ensureCurrentPeriod(uid: String) async throws {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(clean)

        let now = Date()
        let currentWeeklyKey = ScoreKeys.weekKey(for: now)
        let currentMonthlyKey = ScoreKeys.monthKey(for: now)

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.runTransaction({ tx, errPtr -> Any? in
                do {
                    let snap = try tx.getDocument(ref)
                    let data = snap.data() ?? [:]

                    let storedWeeklyKey = data["scoreWeeklyKey"] as? String
                    let storedMonthlyKey = data["scoreMonthlyKey"] as? String

                    var updates: [String: Any] = [
                        "updatedAt": FieldValue.serverTimestamp()
                    ]

                    // ✅ reset semanal si cambió la key (o si no existe)
                    if storedWeeklyKey != currentWeeklyKey {
                        updates["scoreWeekly"] = 0
                        updates["scoreWeeklyKey"] = currentWeeklyKey
                    } else if storedWeeklyKey == nil {
                        updates["scoreWeeklyKey"] = currentWeeklyKey
                    }

                    // ✅ reset mensual si cambió la key (o si no existe)
                    if storedMonthlyKey != currentMonthlyKey {
                        updates["scoreMonthly"] = 0
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    } else if storedMonthlyKey == nil {
                        updates["scoreMonthlyKey"] = currentMonthlyKey
                    }

                    // Si solo está updatedAt, no hace falta escribir
                    if updates.keys.count > 1 {
                        tx.setData(updates, forDocument: ref, merge: true)
                    }

                    return true
                } catch {
                    errPtr?.pointee = error as NSError
                    return nil
                }
            }, completion: { _, error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            })
        }
    }
}
