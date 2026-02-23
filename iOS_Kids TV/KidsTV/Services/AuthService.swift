//
//  AuthService.swift
//  Kids TV - Firebase Auth + Google Sign-In (optional)
//

import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

final class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published private(set) var currentUser: AuthUserProtocol?
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var isSigningIn: Bool = false

    var displayName: String? { currentUser?.displayName }
    var email: String? { currentUser?.email }
    var photoURL: URL? { currentUser?.photoURL }

    private init() {
        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user.map { FirebaseAuthUser(user: $0) }
            self?.isSignedIn = user != nil
        }
        if let user = Auth.auth().currentUser {
            currentUser = FirebaseAuthUser(user: user)
            isSignedIn = true
        }
        #endif
    }

    func signInWithGoogle() async throws {
        isSigningIn = true
        defer { isSigningIn = false }
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        let config = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token"])
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        _ = try await Auth.auth().signIn(with: credential)
        #else
        throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Add Firebase and GoogleSignIn SDK for sign-in."])
        #endif
    }

    func signOut() throws {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #endif
        currentUser = nil
        isSignedIn = false
    }
}

protocol AuthUserProtocol {
    var displayName: String? { get }
    var email: String? { get }
    var photoURL: URL? { get }
}

#if canImport(FirebaseAuth)
private struct FirebaseAuthUser: AuthUserProtocol {
    let user: User
    var displayName: String? { user.displayName }
    var email: String? { user.email }
    var photoURL: URL? { user.photoURL }
}
#endif
