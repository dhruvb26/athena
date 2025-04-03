//
//  AddCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI
import UniformTypeIdentifiers
import FirebaseStorage
import FirebaseFirestore

struct AddNewCourseView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var code = ""
    @State private var semester = ""
    @State private var notificationType: NotificationType = .question
    @State private var difficulty: Difficulty? = .easy
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var documentTitle = "Document"
    @State private var isUploading = false
    @State private var uploadError: Error?

    let storage = Storage.storage()
    let storageRef: StorageReference
    let firestore = Firestore.firestore()

    init() {
        storageRef = storage.reference()
    }

    func uploadDocumentAndSaveCourse() {
        guard let fileURL = selectedFileURL else {
            print("No file selected for upload.")
            saveCourseToFirestore(downloadURL: nil)
            return
        }

        isUploading = true

        guard fileURL.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource.")
            isUploading = false
            uploadError = NSError(domain: "FileAccessError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access the selected file."])
            return
        }

        do {
            let fileData = try Data(contentsOf: fileURL)
            let documentRef = storageRef.child("docs/\(documentTitle)")

            let uploadTask = documentRef.putData(fileData, metadata: nil) { metadata, error in
                
                fileURL.stopAccessingSecurityScopedResource()
                isUploading = false

                if let error = error {
                    print("Error uploading document: \(error.localizedDescription)")
                    uploadError = error
                    saveCourseToFirestore(downloadURL: nil)
                    return
                }

                documentRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        uploadError = error
                        saveCourseToFirestore(downloadURL: nil)
                        return
                    }
                    saveCourseToFirestore(downloadURL: url)
                }
            }
            print("Upload task started.")
        } catch {
            fileURL.stopAccessingSecurityScopedResource()
            isUploading = false
            uploadError = error
            print("Error reading file data: \(error.localizedDescription)")
            saveCourseToFirestore(downloadURL: nil)
        }
    }

    func saveCourseToFirestore(downloadURL: URL?) {
        let document = Document(title: documentTitle, url: downloadURL?.absoluteString ?? "", dateAdded: Date())
        let newCourse = Course(
            name: name,
            code: code,
            semester: semester,
            notificationType: notificationType,
            difficulty: difficulty,
            documents: downloadURL != nil ? [document] : []
        )

        do {
            _ = try firestore.collection("courses").addDocument(from: newCourse) { error in
                if let error = error {
                    print("Error adding document to Firestore: \(error.localizedDescription)")
                } else {
                    print("Course saved to Firestore successfully!")
                    dismiss()
                }
            }
        } catch {
            print("Error encoding course: \(error.localizedDescription)")
        }
    }

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
                        Button("Select Document") {
                            showingFilePicker = true
                        }

                        if let selectedFileURL {
                            VStack(alignment: .leading) {
                                Text("Selected file:")
                                Text(selectedFileURL.lastPathComponent)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            TextField("Document Title", text: $documentTitle)
                        }
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

                Button(action: {
                    uploadDocumentAndSaveCourse()
                    print("Save Course")
                }) {
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
                .disabled(isUploading)

                if isUploading {
                    ProgressView("Uploading...")
                }

                if let error = uploadError {
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
                case .success(let files):
                    if let fileURL = files.first {
                        selectedFileURL = fileURL
                        documentTitle = fileURL.deletingPathExtension().lastPathComponent
                        print(documentTitle)
                        print("File Path: \(fileURL.path())")
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AddNewCourseView()
}
