//
//  UserView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI
import FirebaseAuth

struct UserView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack {
                if let user = authViewModel.user {
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)

                        Text(user.email ?? "No email available")
                            .font(.headline)
                        
                        Spacer()

                        Button {
                            authViewModel.signOut()
                        } label: {
                            Text("Sign Out")
                                .foregroundStyle(Color.secondaryPurple)
                        }
                        
                    }
                } else {
                    Text("Not logged in")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
    }
}

#Preview {
    UserView()
        .environmentObject(AuthViewModel())
}
