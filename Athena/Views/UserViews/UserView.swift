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
        ZStack(alignment: .bottomTrailing) {
            VStack {
                if let user = authViewModel.user {
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
                } else {
                    Text("Not logged in")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Spacer()
            }
            .padding()

            Button {
                authViewModel.signOut()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 35))
            }
            .foregroundStyle(Color.secondaryPurple)
            .padding(.trailing, 45)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    UserView()
        .environmentObject(AuthViewModel())
}
