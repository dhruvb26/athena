//
//  SubjectDetailView.swift
//  MainProject
//
//  Created by Kanav Gupta on 3/29/25.
//

import SwiftUI

struct SubjectDetailView: View {
    var subject: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.8)))
                
                Text(subject)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            Text("Welcome to \(subject)! Here you can edit your uploaded material, change settings and much more!")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle(subject)
    }
    
    
}

#Preview {
    NavigationView {
        SubjectDetailView(subject: "CSE 335")
    }
}

