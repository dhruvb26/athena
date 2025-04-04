//
//  SignInView.swift
//  Athena
//
//  Created by Kanav Gupta on 3/28/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false

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

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button {
                Task {
                    if let error = await auth.signInWithEmail(email: email, password: password) {
                        errorMessage = error
                    }
                }
            } label: {
                Text("Sign In")
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

                    Text("Sign In with Google")
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
    }
}

#Preview {
    SignInView()
}
