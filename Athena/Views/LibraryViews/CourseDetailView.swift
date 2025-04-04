//
//  CourseDetailView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct CourseDetailView: View {
    let course: Course
    let storage = Storage.storage()
    @State private var isPresentingEditView = false
    @State private var fileNames: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

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
            
            if isLoading {
                ProgressView()
                    .padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            } else if fileNames.isEmpty {
                Text("No files found for this course")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(fileNames, id: \.self) { fileName in
                        HStack {
                            Image(systemName: "doc")
                            Text(fileName)
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
            await loadFiles()
        }
    }
    
    func loadFiles() async {
        isLoading = true
        errorMessage = nil
        
//        will have to associate a file with user id, so
        // path becomes docs/uid
        
        let storageReference = storage.reference().child("docs/")
        
        do {
            let result = try await storageReference.listAll()
            
            // Update on main thread since we're updating UI state
            await MainActor.run {
                fileNames = result.items.map { $0.name }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error loading files: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    let previewCourses = exampleCourses
    CourseDetailView(course: previewCourses.first!)
}
