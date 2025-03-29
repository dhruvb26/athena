//
//  UserView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/28/25.
//

import SwiftUI

struct UserView: View {
    @StateObject var authVM = AuthViewModel()

    var body: some View {
        if let user = authVM.user {
            Text("Welcome, \(user.email ?? "Unknown")")
        } else {
            Text("Not signed in.")
        }
    }
}

#Preview {
    UserView()
}
