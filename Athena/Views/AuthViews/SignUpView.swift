//
//  SignUpView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPassWordVisible = false
    
    var body: some View {
        VStack(spacing:10) {
            TextField("Email", text: $email)
                .padding()
            
                .cornerRadius(8)
                .padding(.horizontal,15)
                .autocapitalization(.none)
            
            HStack(spacing:0){
                
                if isPasswordVisible{
                    TextField("Password", text: $password)
                        .padding()
                    
                        .cornerRadius(8)
                        .padding(.horizontal,15)
                        .autocapitalization(.none)
                } else {
                    SecureField("Password", text: $password)
                        .padding()
                    
                        .cornerRadius(8)
                        .padding(.horizontal,15)
                        .autocapitalization(.none)
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(Color.gray)
                        .padding(.trailing, 25)
                }
            }
            
            if !password.isEmpty {
                HStack(spacing: 0) {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .cornerRadius(8)
                        .padding(.horizontal, 15)
                    
                    Button(action: {
                        isConfirmPassWordVisible.toggle()
                    }) {
                        Image(systemName: isConfirmPassWordVisible ? "eye.slash" : "eye")
                            .foregroundStyle(Color.gray)
                            .padding(.trailing, 25)
                    }
                    
                }
            }
            
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: signUp) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal,12)
                    .padding(.vertical,14)
                    .foregroundStyle(.white)
                    .background(Color.primaryPurple)
                    .cornerRadius(8)
                    .fontWeight(.semibold)
            }
            .padding(15)
            
            Text("Or")
                .foregroundStyle(Color.gray)
            
            Button(action: signInWithGoogle) {
                HStack(spacing: 10) {
                    Image("Google")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    
                    Text("Sign Up with Google")
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
                .cornerRadius(8)
            }.buttonStyle(PlainButtonStyle())
            
            
        }
        .padding()
        
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Successful"),
                  message: Text("Your account has been created."),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private func signUp() {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password must not be empty."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                showSuccessAlert = true
            }
        }
    }
    
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Missing Client ID"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Unable to access root view controller"
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.errorMessage = "Failed to retrieve Google credentials"
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.errorMessage = "Firebase Sign-In failed: \(error.localizedDescription)"
                } else {
                    print("✅ Firebase user signed in: \(authResult?.user.uid ?? "Unknown")")
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}
