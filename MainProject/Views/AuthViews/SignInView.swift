    //
    //  SignInView.swift
    //  MainProject
    //
    //  Created by Dhruv Bansal on 3/28/25.
    //
    import SwiftUI
    import FirebaseAuth
    import FirebaseCore
    import GoogleSignIn

    struct SignInView: View {
        
        @State private var email = ""
        @State private var password = ""
        @State private var errorMessage: String?
        @State private var isSignedIn = false
        @State private var isPasswordVisible = false
        
        var body: some View {
            VStack(spacing:10) {
                TextField("Email", text: $email)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal,15)
                    .autocapitalization(.none)
                
                HStack(spacing:0){
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal,15)
                            .autocapitalization(.none)
                    } else {
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal,15)
                            .autocapitalization(.none)
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.white)
                            .padding(.trailing, 25)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: signInWithEmail) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal,12)
                        .padding(.vertical,14)
                        .foregroundStyle(.white)
                        .background(Color.black)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                }
                .tint(.black)
                .padding(15)
                
                Text("Or")
                    .foregroundStyle(Color.white)
                
                VStack {
                    Button(action: signInWithGoogle) {
                        HStack(spacing: 10) {
                            Image("Google")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign In with Google")
                                .foregroundStyle(.black)
                                .fontWeight(.semibold)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .shadow(color: Color(UIColor.systemGray).opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .padding(15)
            }
            .padding()
        }

        private func signInWithEmail() {
            errorMessage = nil

            guard !email.isEmpty, !password.isEmpty else {
                errorMessage = "Please fill in all fields."
                return
            }

            Auth.auth().signIn(withEmail: email, password: password) { _, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    isSignedIn = true
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

            // Get the root view controller
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
                        self.isSignedIn = true
                        print("✅ Firebase user signed in: \(authResult?.user.uid ?? "Unknown")")
                    }
                }
            }
        }

    }

    #Preview {
        SignInView()
    }
