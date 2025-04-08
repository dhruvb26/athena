//
//  ContentView.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.user != nil {
                TabView {
                    NavigationView {
                        QuestionView()
                    }
                    .tabItem {
                        Label("", systemImage: "magnifyingglass")
                    }
                    NavigationView {
                        LibraryView()
                            .navigationTitle("Library")
                    }
                    .tabItem {
                        Label("", systemImage: "tray.circle")
                    }
                    NavigationView {
                        UserView()
                            .navigationTitle("Settings")
                    }
                    .tabItem {
                        Label("", systemImage: "gear.circle")
                    }
                }
                .tint(.secondaryPurple)
            } else {
                NavigationView {
                    SignUpOrSignInView()
                        .navigationTitle("Sign Up")
                }
            }
        }
        .environmentObject(authVM)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
