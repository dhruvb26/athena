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
    @StateObject private var quizModel = CourseQuizNotificationViewModel.shared
    @State private var isPresentingEditView = false
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var documentTitle: String = ""
    @State private var isShowingDocumentSheet = false

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                // Top section - course info
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
                .frame(height: geometry.size.height * 0.4)
                .padding(.bottom)

                // Middle section - course files
                VStack(alignment: .leading) {
                    Text("Course Files")
                        .font(.headline)

                    ZStack {
                        if viewModel.isLoading || anotherModel.isUploading {
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
                                        Image(systemName: "document.fill")
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
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: geometry.size.height * 0.4)

                Spacer()

                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Document")
                    }
                    .foregroundStyle(Color.secondaryPurple)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
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
        .sheet(isPresented: $isShowingDocumentSheet) {
            NavigationView {
                VStack {
                    if let fileURL = selectedFileURL {
                        Form {
                            Section(header: Text("Document Information")) {
                                VStack(alignment: .leading) {
                                    Text(fileURL.lastPathComponent)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                TextField("Document Title", text: $documentTitle)
                            }
                        }
                    }

                    Button {
                        if let fileURL = selectedFileURL {
                            Task {
                                anotherModel.uploadDocument(
                                    for: course,
                                    fileURL: fileURL,
                                    title: documentTitle
                                ) {
                                    Task {
                                        await viewModel.loadDocuments(for: course)
                                        quizModel.scheduleQuizNotification()
                                    }
                                }
                            }
                            isShowingDocumentSheet = false
                        }
                    } label: {
                        Text("Upload Document")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.primaryPurple)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                    .padding(15)
                }
                .navigationTitle("Document Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isShowingDocumentSheet = false
                        }
                    }
                }
            }
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
                    isShowingDocumentSheet = true
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
