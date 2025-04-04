//
//  SignUpView.swift
//  Athena
//
//  Created by Kanav Gupta on 3/28/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPassWordVisible = false

    var body: some View {
        VStack(spacing: 10) {
            TextField("Email", text: $email)
                .padding()
                .cornerRadius(8)
                .padding(.horizontal, 15)
                .autocapitalization(.none)

            HStack(spacing: 0) {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .padding()
                        .cornerRadius(8)
                        .padding(.horizontal, 15)
                        .autocapitalization(.none)
                } else {
                    SecureField("Password", text: $password)
                        .padding()
                        .cornerRadius(8)
                        .padding(.horizontal, 15)
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

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button {
                Task {
                    let error = await auth.createUserWithEmail(
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                    if let error {
                        errorMessage = error
                    } else {
                        showSuccessAlert = true
                    }
                }
            } label: {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.primaryPurple)
                    .cornerRadius(8)
                    .fontWeight(.semibold)
            }
            .padding(15)

            Text("Or")
                .foregroundStyle(Color.gray)

            Button {
                Task {
                    if let error = await auth.signInWithGoogle() {
                        errorMessage = error
                    }
                }
            } label: {
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
            }
            .buttonStyle(.plain)
        }
        .padding()
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Successful"),
                  message: Text("Your account has been created."),
                  dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    SignUpView()
}
