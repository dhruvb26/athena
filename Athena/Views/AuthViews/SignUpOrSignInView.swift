//
//  SignUpOrSignInView.swift
//  Athena
//
//  Created by Kanav Gupta on 3/28/25.
//

import SwiftUI

struct SignUpOrSignInView: View {
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            VStack {
                Text("athena")
                    .foregroundStyle(.primary)
                    .font(Font(CustomFont.agaramondProRegular.withSize(40)))

                Spacer()
                    .frame(height: 30)

                if isSignUp {
                    SignUpView()
                } else {
                    SignInView()
                }

                HStack(spacing: 0) {
                    Text(isSignUp ? "Already have an account? " : "Don't have an account? ")
                        .foregroundStyle(.primary)
                    Button {
                        isSignUp.toggle()
                    } label: {
                        Text(isSignUp ? "Sign in" : "Sign up")
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

#Preview {
    SignUpOrSignInView()
}
