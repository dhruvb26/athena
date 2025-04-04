//
//  AddCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddCourseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CourseAddViewModel()

    @State private var name = ""
    @State private var code = ""
    @State private var semester = ""
    @State private var documentTitle = "Document"
    @State private var selectedFileURL: URL?
    @State private var notificationType: NotificationType = .question
    @State private var difficulty: Difficulty? = .easy
    @State private var showingFilePicker = false

    var body: some View {
        NavigationView {
            VStack {
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
                        Button("Select Document") {
                            showingFilePicker = true
                        }

                        if let fileURL = selectedFileURL {
                            VStack(alignment: .leading) {
                                Text("Selected file:")
                                Text(fileURL.lastPathComponent)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            TextField("Document Title", text: $documentTitle)
                        }
                    }
                }
                .navigationTitle("New Course")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                Button {
                    viewModel.uploadCourse(
                        name: name,
                        code: code,
                        semester: semester,
                        notificationType: notificationType,
                        difficulty: difficulty,
                        documentTitle: documentTitle,
                        selectedFileURL: selectedFileURL
                    ) {
                        dismiss()
                    }
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color.primaryPurple)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                }
                .padding(15)
                .disabled(viewModel.isUploading)

                if viewModel.isUploading {
                    ProgressView("Uploading...")
                }

                if let error = viewModel.uploadError {
                    Text("Upload Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                        .padding(.top)
                }
            }
            .tint(Color.secondaryPurple)
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType.pdf, UTType.presentation, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case let .success(files):
                    if let fileURL = files.first {
                        selectedFileURL = fileURL
                        documentTitle = fileURL.deletingPathExtension().lastPathComponent
                    }
                case let .failure(error):
                    print("❌ File selection error: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AddCourseView()
}
