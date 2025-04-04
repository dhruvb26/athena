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
    @StateObject private var anotherModel = CourseEditViewModel()
    @State private var isPresentingEditView = false
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var documentTitle: String = ""

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

            Text("Course Files")
                .font(.headline)
                .padding(.top)

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if viewModel.documents.isEmpty {
                Text("No files found for this course.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.documents) { document in
                        HStack {
                            Image(systemName: "doc")
                                .foregroundStyle(.gray)
                            Text(document.title)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    anotherModel.deleteDocument(
                                        course: course,
                                        document: document
                                    ) {
                                        Task {
                                            await viewModel.loadDocuments(for: course)
                                        }
                                    }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }

            Spacer()

            Button {
                showingFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Document")
                }
                .foregroundStyle(Color.secondaryPurple)
            }
            .padding()
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
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .presentation],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let fileURL = urls.first {
                    selectedFileURL = fileURL
                    documentTitle = fileURL.deletingPathExtension().lastPathComponent
                    Task {
                        anotherModel.uploadDocument(
                            for: course,
                            fileURL: fileURL,
                            title: documentTitle
                        ) {
                            Task {
                                await viewModel.loadDocuments(for: course)
                            }
                        }
                    }
                }
            case let .failure(error):
                print("File import failed: \(error)")
            }
        }
        .onChange(of: isPresentingEditView) { _, newValue in
            if !newValue {
                Task {
                    await viewModel.loadDocuments(for: course)
                }
            }
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
