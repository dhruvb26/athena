//
//  CourseDetailView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI

struct CourseDetailView: View {
    let course: Course
    @StateObject private var viewModel = CourseDetailViewModel()
    @State private var isPresentingEditView = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.gray)

            Text("\(course.semester)")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Divider()

            Text("Course Files")
                .font(.headline)
                .padding(.top)

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if viewModel.documents.isEmpty {
                Text("No files found for this course")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.documents) { document in
                        HStack {
                            Image(systemName: "doc")
                            Text(document.title)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Course Details")
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
        .task {
            await viewModel.loadDocuments(for: course)
        }
    }
}

#Preview {
    let previewCourses = exampleCourses
    CourseDetailView(course: previewCourses.first!)
}
