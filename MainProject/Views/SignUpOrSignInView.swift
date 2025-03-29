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
        VStack {
            Spacer()

            if isSignUp {
                SignUpView()
            } else {
                SignInView()
            }

            Spacer()
            
            HStack(spacing:0){
                Text(isSignUp ? "Already have an account? " : "Don't have an account? ")
                    .foregroundStyle(Color(UIColor.systemGray))
                Button {
                    isSignUp.toggle()
                } label: {
                    Text(isSignUp ? "Sign in" : "Sign up")
                        .foregroundColor(.black)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        
    }
}

#Preview {
    SignUpOrSignInView()
}
