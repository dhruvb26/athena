//
//  EditCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct EditCourseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CourseEditViewModel()
    @State var course: Course

    @State private var name: String
    @State private var code: String
    @State private var semester: String
    @State private var notificationType: NotificationType
    @State private var difficulty: Difficulty?
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var documentTitle: String
    @State private var documentToDelete: Document?

    init(course: Course) {
        _course = State(initialValue: course)
        _name = State(initialValue: course.name)
        _code = State(initialValue: course.code)
        _semester = State(initialValue: course.semester)
        _notificationType = State(initialValue: course.notificationType)
        _difficulty = State(initialValue: course.difficulty)
        _documentTitle = State(initialValue: course.documents.first?.title ?? "Document")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                Form {
                    Section {
                        TextField("Course Name", text: $name)
                        TextField("Course Code", text: $code)
                        TextField("Semester", text: $semester)
                    }

                    Section {
                        Picker("Notification Type", selection: $notificationType) {
                            Text("Question").tag(NotificationType.question)
                            Text("Snippet").tag(NotificationType.snippet)
                            Text("Mixed").tag(NotificationType.mixed)
                        }
                    }

                    Section {
                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag(Difficulty.easy as Difficulty?)
                            Text("Medium").tag(Difficulty.medium as Difficulty?)
                            Text("Hard").tag(Difficulty.hard as Difficulty?)
                        }
                    }

                    Section {
                        if let document = course.documents.first {
                            HStack {
                                Text(document.title)
                                Spacer()
                                Button(role: .destructive) {
                                    documentToDelete = document
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .alert(item: $documentToDelete) { document in
                                Alert(
                                    title: Text("Delete Document"),
                                    message: Text("Are you sure you want to delete '\(document.title)'?"),
                                    primaryButton: .destructive(Text("Delete")) {
                                        viewModel.deleteDocument(course: course, document: document) {
                                            if let index = course.documents.firstIndex(where: { $0.id == document.id }) {
                                                course.documents.remove(at: index)
                                            }
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        } else {
                            Text("No documents attached.")
                                .foregroundColor(.secondary)
                        }

                        Button("Add Document") {
                            showingFilePicker = true
                        }

                        if let fileURL = selectedFileURL {
                            VStack(alignment: .leading) {
                                Text("Selected file: \(fileURL.lastPathComponent)")
                                TextField("Document Title", text: $documentTitle)
                            }
                        }

                        if viewModel.isUploading {
                            ProgressView("Uploading...")
                        }

                        if let error = viewModel.uploadError {
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                        }
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        viewModel.updateCourse(course, name: name, code: code, semester: semester, notificationType: notificationType, difficulty: difficulty) {
                            if selectedFileURL != nil {
                                viewModel.uploadDocument(for: course, fileURL: selectedFileURL!, title: documentTitle) {
                                    dismiss()
                                }
                            } else {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.primaryPurple)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isUploading || viewModel.isDeleting)
                }
                .padding(.bottom)
            }
            .navigationTitle("Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .tint(Color.secondaryPurple)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.pdf, UTType.presentation, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(urls):
                    if let fileURL = urls.first {
                        selectedFileURL = fileURL
                        documentTitle = fileURL.deletingPathExtension().lastPathComponent
                    }
                case let .failure(error):
                    print("File import failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    let previewCourses = exampleCourses
    return EditCourseView(course: previewCourses.first!)
}
