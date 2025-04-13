//
//  AuthViewModel.swift
//  Athena
//
//  Created by Kanav Gupta on 3/28/25.
//

import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var user: User?

    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }

        getAuthUser()
    }

    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func getAuthUser() {
        user = Auth.auth().currentUser
    }

    func getAuthUserId() -> String {
        user?.uid ?? ""
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func createUserWithEmail(email: String, password: String, confirmPassword: String) async -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return "Email and password must not be empty."
        }

        guard password == confirmPassword else {
            return "Passwords do not match."
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func signInWithGoogle() async -> String? {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return "An error occurred: missing client ID."
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController
        else {
            return "An error occurred: could not access root view controller."
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                return "An error occurred: failed to retrieve Google ID token."
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user

            return nil
        } catch {
            return "Sign-In failed: \(error.localizedDescription)"
        }
    }

    func signInWithEmail(email: String, password: String) async -> String? {
        guard !email.isEmpty, !password.isEmpty else {
            return "Please fill in all fields."
        }

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
            return nil
        } catch {
            return "Sign-In failed: \(error.localizedDescription)"
        }
    }
}
