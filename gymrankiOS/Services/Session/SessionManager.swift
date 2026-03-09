//
//  SessionManager.swift
//  gymrankiOS
//

import Foundation
import FirebaseAuth

@MainActor
final class SessionManager: ObservableObject {

    @Published private(set) var userId: String = ""

    private var handle: AuthStateDidChangeListenerHandle?
    private var isEnsuringPeriod = false

    init() {
        userId = Auth.auth().currentUser?.uid ?? ""

        // Si ya estaba logueado al iniciar, aseguramos período
        if !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { await ensureScorePeriodIfNeeded(uid: userId) }
        }

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            let newUid = user?.uid ?? ""
            self.userId = newUid

            if !newUid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await self.ensureScorePeriodIfNeeded(uid: newUid) }
            }
        }
    }

    var isLoggedIn: Bool { !userId.isEmpty }

    private func ensureScorePeriodIfNeeded(uid: String) async {
        // evita correr 2 veces en paralelo (ej: cambios rápidos de Auth)
        guard !isEnsuringPeriod else { return }
        isEnsuringPeriod = true
        defer { isEnsuringPeriod = false }

        do {
            try await ScoreResetter.ensureCurrentPeriod(uid: uid)
        } catch {
            // No bloquees el login por esto. Loguealo si querés.
            print("ScoreResetter error:", error.localizedDescription)
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }
    
    func refreshPeriodIfNeeded() async {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return }
        await ensureScorePeriodIfNeeded(uid: uid)
    }
}

