//
//  AuthService.swift
//  gymrankiOS
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import UIKit

final class AuthService {
    static let shared = AuthService()
    private init() {}

    var currentUserId: String? { Auth.auth().currentUser?.uid }
    var isLoggedIn: Bool { Auth.auth().currentUser != nil }

    private var currentAppleNonce: String?

    // MARK: - Email/Password

    func register(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func login(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    func logout() throws {
        try Auth.auth().signOut()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Google

    func signInWithGoogle() async throws -> String {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase clientID"])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootVC = await topViewController() else {
            throw NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard
            let idToken = result.user.idToken?.tokenString,
            let accessToken = result.user.accessToken.tokenString as String?
        else {
            throw NSError(domain: "AuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing Google tokens"])
        }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user.uid
    }

    // MARK: - Apple (SwiftUI SignInWithAppleButton)

    /// Llamalo en SignInWithAppleButton.onRequest { ... }
    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentAppleNonce = nonce

        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Llamalo en SignInWithAppleButton.onCompletion { ... }
    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async throws -> String {
        switch result {
        case .failure(let error):
            throw error

        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AuthService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"])
            }

            guard let nonce = currentAppleNonce else {
                throw NSError(domain: "AuthService", code: -11, userInfo: [NSLocalizedDescriptionKey: "Missing nonce. Reintenta."])
            }

            guard
                let appleToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleToken, encoding: .utf8)
            else {
                throw NSError(domain: "AuthService", code: -12, userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token"])
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            currentAppleNonce = nil
            return authResult.user.uid
        }
    }

    // MARK: - Helpers

    @MainActor
    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        return root.topMost()
    }
}

private extension UIViewController {
    func topMost() -> UIViewController {
        if let presented = presentedViewController { return presented.topMost() }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.topMost() ?? nav }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topMost() ?? tab }
        return self
    }
}

// MARK: - Apple nonce helpers

private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        if errorCode != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }

        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
}
