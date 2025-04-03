//
//  CourseDetailView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @State private var isPresentingEditView = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("\(course.semester)")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isPresentingEditView = true
                }
            }
        }
        .sheet(isPresented: $isPresentingEditView) {
            EditCourseView(course: course)
        }
    }
}

#Preview {
    let previewCourses = exampleCourses
    CourseDetailView(course: previewCourses.first!)
}
