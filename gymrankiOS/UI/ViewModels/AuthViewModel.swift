//
//  AuthViewModel.swift
//  gymrankiOS
//
//  Created by Martin Backhaus on 17/02/2026.
//

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func login(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await AuthService.shared.login(email: email, password: password)
        } catch {
            errorMessage = userFriendly(error)
        }
    }

    /// Crea usuario en Firebase Auth y también crea users/{uid} en Firestore.
    func register(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // Asumimos que AuthService.register devuelve uid (String)
            let uid = try await AuthService.shared.register(email: email, password: password)

            // Crea documento inicial del usuario en Firestore (si no existe)
            try await UserRepository.shared.createUserDocumentIfNeeded(uid: uid, email: email)
        } catch {
            errorMessage = userFriendly(error)
        }
    }

    func logout() {
        do {
            try AuthService.shared.logout()
        } catch {
            errorMessage = userFriendly(error)
        }
    }

    func resetPassword(email: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.sendPasswordReset(email: email)
        } catch {
            errorMessage = userFriendly(error)
        }
    }
    
    func loginWithGoogle() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await AuthService.shared.signInWithGoogle()
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func userFriendly(_ error: Error) -> String {
        (error as NSError).localizedDescription
    }
}
