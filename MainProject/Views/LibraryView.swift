//
//  LibraryView.swift
//  MainProject
//
//  Created by Kanav Gupta on 3/29/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var subjects = ["CSE 335", "MTH 241"]
    @State private var searchText = ""

    var filteredSubjects: [String] {
        if searchText.isEmpty {
            return subjects
        } else {
            return subjects.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(filteredSubjects, id: \.self) { subject in
                            SubjectCard(subject: subject)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("📚 My Subjects")
        }
    }
}

struct SubjectCard: View {
    var subject: String
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.8)))
            
            Text(subject)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 3)
    }

}



struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search subjects...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .autocapitalization(.none)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
        .padding(.horizontal)
    }
}

=======
//  Created by Dhruv Bansal on 3/29/25.
//
import SwiftUI

struct LibraryView: View {
    @State private var courses = exampleCourses

    var body: some View {
        NavigationView {
            List {
                ForEach(courses) { course in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title)
                            .font(.headline)
                        Text(course.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("by \(course.author)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: deleteCourse)
            }
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("Add course tapped")
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteCourse(at offsets: IndexSet) {
        courses.remove(atOffsets: offsets)
    }
}

#Preview {
    LibraryView()
}
