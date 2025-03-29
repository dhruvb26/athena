//
//  LibraryView.swift
//  MainProject
//
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
