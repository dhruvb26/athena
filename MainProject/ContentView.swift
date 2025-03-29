//
//  ContentView.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var authVM = AuthViewModel()

    var body: some View {
        VStack {
            if let _ = authVM.user {
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.medium)
                Button(action: authVM.signOut){
                    Text("Sign out")
                }
            } else {
                SignUpOrSignInView()
            }
        }
    }
}

#Preview {
    ContentView()
}
