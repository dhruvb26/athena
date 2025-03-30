//
//  SignUpOrSignInView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/28/25.
//

import SwiftUI

struct SignUpOrSignInView: View {
    @State private var isSignUp = true

    var body: some View {
        
        ZStack{
            Image("AuthBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                
                Text("athena")
                    .foregroundStyle(Color.white)
                    .font(.system(size: 34)) // ← Set any custom point size

                
                Spacer()
                    .frame(height: 30)
                
                
                if isSignUp {
                    SignUpView()
                } else {
                    SignInView()
                }
                
                
                HStack(spacing:0){
                    Text(isSignUp ? "Already have an account? " : "Don't have an account? ")
                        .foregroundStyle(Color.white)
                    Button {
                        isSignUp.toggle()
                    } label: {
                        Text(isSignUp ? "Sign in" : "Sign up")
                            .foregroundStyle(Color.white)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        
    }
}

#Preview {
    SignUpOrSignInView()
}
