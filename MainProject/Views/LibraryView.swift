//
//  LibraryView.swift
//  MainProject
//
//  Created by Kanav Gupta & Dhruv Bansal on 3/29/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var searchText = ""
    @State private var courses = exampleCourses

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List {
                    ForEach(filteredCourses) { course in
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
            }
            .navigationTitle("📚 My Courses")
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

// SearchBar remains unchanged
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search courses...", text: $text)
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

#Preview {
    LibraryView()
}
