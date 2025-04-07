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
            if let _ = authVM.user {
                TabView {
                    QuestionView()
                        .tabItem {
                            Label("", systemImage: "magnifyingglass")
                        }
                    LibraryView()
                        .tabItem {
                            Label("", systemImage: "tray.circle")
                        }
                    FriendsView()
                        .tabItem {
                            Label("", systemImage: "person.2.circle")
                        }
                    UserView()
                        .tabItem {
                            Label("", systemImage: "gear.circle")
                        }
                }
            } else {
                SignUpOrSignInView()
            }
        }
        .environmentObject(authVM)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
