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

    init() {
        userId = Auth.auth().currentUser?.uid ?? ""

        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userId = user?.uid ?? ""
        }
    }

    var isLoggedIn: Bool { !userId.isEmpty }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }
}
