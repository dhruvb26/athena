//
//  UserView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import FirebaseAuth
import SwiftUI

struct UserView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var quizViewModel = QuizViewModel()

    var body: some View {
        ZStack {
            VStack {
                if let user = authViewModel.user {
                    VStack {
                        HStack {
                            Text("Email")
                                .font(.headline)

                            Spacer()

                            Text(user.email ?? "No email available")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        Button {
                            Task {
                                try await quizViewModel.scheduleQuizItemsFromDb()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Schedule Quiz Items")
                            }
                            .foregroundStyle(Color.secondaryPurple)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()

                        Spacer()

                        Button {
                            authViewModel.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Sign Out")
                            }
                            .foregroundStyle(Color.secondaryPurple)
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    }
                } else {
                    Text("Not logged in")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding()
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    UserView()
        .environmentObject(AuthViewModel())
}
