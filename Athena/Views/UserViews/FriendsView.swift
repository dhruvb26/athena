//
//  FriendsView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/7/25.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Catch up with your friends.")
                }
                .navigationTitle("Friends")
                .padding()
            }
        }
    }
}

#Preview {
    FriendsView()
}
