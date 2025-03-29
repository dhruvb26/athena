//
//  SignUpView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/28/25.
//
import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false

    var body: some View {
        ZStack {
            VStack {
                TextField("Email", text: $email)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal,15)
                .autocapitalization(.none)

                SecureField("Password", text: $password)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(.horizontal,15)
                
                if !password.isEmpty{
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.horizontal,15)
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
                        .background(Color.black)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                }
                .tint(.black)
                .padding(15)
                
                Text("Or")
                .foregroundStyle(Color(UIColor.systemGray))

                VStack{
                    
                    Button(action: signUp) {
                        HStack(spacing: 10) {
                            Image("AppleDark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign Up with Apple")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                    
                    Button(action: signUp) {
                        HStack(spacing: 10) {
                            Image("Google")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                            
                            Text("Sign Up with Google")
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
                
                HStack{                 
                    Text("Already have an account?")
                        .font(.callout)
                        .foregroundStyle(Color(UIColor.systemGray))
                }
            }
            .padding()
        }
        .alert(isPresented: $showSuccessAlert) {
            Alert(title: Text("Sign Up Successful"),
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
}

#Preview {
    SignUpView()
}
