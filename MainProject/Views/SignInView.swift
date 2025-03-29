//
//  SignInView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/28/25.
//
import SwiftUI
import FirebaseAuth

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
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding(.horizontal,15)
            .autocapitalization(.none)
            
            HStack(spacing:0){
                
                if isPasswordVisible{
                    TextField("Password", text: $password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.horizontal,15)
                        .autocapitalization(.none)
                } else {
                    SecureField("Password", text: $password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.horizontal,15)
                        .autocapitalization(.none)
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                               .foregroundColor(.gray)
                               .padding(.trailing, 25)
                }
            }
            

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: signIn) {
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
            .foregroundStyle(Color(UIColor.systemGray))

            VStack{
                
                Button(action: signIn) {
                    HStack(spacing: 10) {
                        Image("AppleDark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                        
                        Text("Sign In with Apple")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(8)
                }

                Button(action: signIn) {
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
        .fullScreenCover(isPresented: $isSignedIn) {
            Text("You’re signed in!")
        }
    }

    private func signIn() {
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
}


#Preview {
    SignInView()
}
