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
    @State private var isPasswordVisible = false
    @State private var isConfirmPassWordVisible = false

    var body: some View {
            VStack(spacing:10) {
                TextField("Email", text: $email)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal,15)
                .autocapitalization(.none)
                

                HStack(spacing:0){
                    
                    if isPasswordVisible{
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
                
                if !password.isEmpty{
                    
                    HStack(spacing:0){
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.horizontal,15)
                        
                        Button(action: {
                            isConfirmPassWordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPassWordVisible ? "eye.slash" : "eye")
                                       .foregroundColor(.white)
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
                        .background(Color.black)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                }
                .tint(.black)
                .padding(15)
                
                Text("Or")
                    .foregroundStyle(Color.white)

                VStack{
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
                   
                }
                .padding(15)
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
}

#Preview {
    SignUpView()
}
