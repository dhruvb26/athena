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

    var body: some View {
        NavigationView {
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
                .navigationTitle("Settings")
                .padding()
            }
        }
    }
}

#Preview {
    UserView()
        .environmentObject(AuthViewModel())
}
