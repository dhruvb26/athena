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
import Logging

class AuthViewModel: ObservableObject {
    private let logger = Logger(label: "athena.AuthViewModel")

    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

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
            logger.error("Error signing out: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func createUserWithEmail(email: String, password: String, confirmPassword: String) async {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password must not be empty."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            isLoading = true
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            user = result.user
        } catch {
            logger.error("Error creating user: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signInWithGoogle() async {
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "An error occurred: missing client ID."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController
        else {
            errorMessage = "An error occurred: could not access root view controller."
            return
        }

        do {
            isLoading = true
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "An error occurred: failed to retrieve Google ID token."
                isLoading = false
                return
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user
        } catch {
            logger.error("Sign-In with Google failed: \(error.localizedDescription)")
            errorMessage = "Sign-In failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func signInWithEmail(email: String, password: String) async {
        errorMessage = nil

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }

        do {
            isLoading = true
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            user = result.user
        } catch {
            logger.error("Sign-In failed: \(error.localizedDescription)")
            errorMessage = "Sign-In failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
