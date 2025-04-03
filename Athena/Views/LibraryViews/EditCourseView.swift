//
//  EditCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import SwiftUI
import UniformTypeIdentifiers
import FirebaseStorage
import FirebaseFirestore

struct EditCourseView: View {
    @Environment(\.dismiss) var dismiss
    @State var course: Course // Receive the course to edit
    
    @State private var name: String
    @State private var code: String
    @State private var semester: String
    @State private var notificationType: NotificationType
    @State private var difficulty: Difficulty?
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var documentTitle: String
    @State private var isUploading = false
    @State private var uploadError: Error?
    @State private var isDeletingDocument = false
    @State private var documentToDelete: Document?
    
    let storage = Storage.storage()
    let storageRef: StorageReference
    let firestore = Firestore.firestore()
    
    init(course: Course) {
        self._course = State(initialValue: course)
        _name = State(initialValue: course.name)
        _code = State(initialValue: course.code)
        _semester = State(initialValue: course.semester)
        _notificationType = State(initialValue: course.notificationType)
        _difficulty = State(initialValue: course.difficulty)
        _documentTitle = State(initialValue: course.documents.first?.title ?? "Document") // Assuming only one document for simplicity
        storageRef = storage.reference()
    }
    
    func updateCourse() {
        // Create a dictionary with the updated fields
        var updatedData: [String: Any] = [
            "name": name,
            "code": code,
            "semester": semester,
            "notificationType": notificationType.rawValue,
            "difficulty": difficulty?.rawValue as Any
        ]
        
        // Update the document in Firestore
        if let courseId = course.docID {
            firestore.collection("courses").document(courseId).updateData(updatedData) { error in
                if let error = error {
                    print("Error updating course: \(error.localizedDescription)")
                    // Handle error appropriately
                } else {
                    print("Course updated successfully!")
                    dismiss()
                }
            }
        }
    }
    
    func uploadNewDocument() {
        guard let fileURL = selectedFileURL else {
            print("No file selected for upload.")
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
            let documentRef = storageRef.child("docs/\(documentTitle)_\(UUID().uuidString)") // Append UUID for unique names
            
            _ = documentRef.putData(fileData, metadata: nil) { metadata, error in
                fileURL.stopAccessingSecurityScopedResource()
                isUploading = false
                
                if let error = error {
                    print("Error uploading document: \(error.localizedDescription)")
                    uploadError = error
                    return
                }
                
                documentRef.downloadURL { (url, error) in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        uploadError = error
                        return
                    }
                    if let downloadURL = url {
                        saveNewDocumentToCourse(downloadURL: downloadURL)
                    }
                }
            }
            print("Upload task started.")
        } catch {
            fileURL.stopAccessingSecurityScopedResource()
            isUploading = false
            uploadError = error
            print("Error reading file data: \(error.localizedDescription)")
        }
    }
    
    func saveNewDocumentToCourse(downloadURL: URL) {
        let newDocument = Document(title: documentTitle, url: downloadURL.absoluteString, dateAdded: Date())
        if let courseId = course.docID {
            firestore.collection("courses").document(courseId).updateData([
                "documents": FieldValue.arrayUnion([newDocument.firestoreRepresentation()])
            ]) { error in
                if let error = error {
                    print("Error adding document to Firestore: \(error.localizedDescription)")
                    // Handle error
                } else {
                    print("New document added to course.")
                    // Optionally refresh the course data
                }
            }
        }
    }
    
    func confirmDeleteDocument(document: Document) {
        documentToDelete = document
    }
    
    func deleteDocument(document: Document) {
        guard let courseId = course.docID else {
            print("Error: Course has no ID.")
            return
        }
        
        isDeletingDocument = true
        
        if let fileURL = document.url {
            let storageReference = Storage.storage().reference(forURL: fileURL)
            storageReference.delete { error in
                if let error = error {
                    print("Error deleting document from storage: \(error.localizedDescription)")
                    isDeletingDocument = false
                    return
                }
                print("Document deleted from storage.")
                
                // Delete reference from Firestore
                firestore.collection("courses").document(courseId).updateData([
                    "documents": FieldValue.arrayRemove([document.firestoreRepresentation()])
                ]) { error in
                    isDeletingDocument = false
                    if let error = error {
                        print("Error removing document reference from Firestore: \(error.localizedDescription)")
                    } else {
                        print("Document reference removed from Firestore.")
                        if let index = course.documents.firstIndex(where: { $0.id == document.id }) {
                            course.documents.remove(at: index)
                        }
                    }
                }
            }
        } else {
            // If URL is nil, just remove from Firestore
            firestore.collection("courses").document(courseId).updateData([
                "documents": FieldValue.arrayRemove([document.firestoreRepresentation()])
            ]) { error in
                isDeletingDocument = false
                if let error = error {
                    print("Error removing document reference from Firestore: \(error.localizedDescription)")
                } else {
                    print("Document reference removed from Firestore.")
                    if let index = course.documents.firstIndex(where: { $0.id == document.id }) {
                        course.documents.remove(at: index)
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Course Information")) {
                        TextField("Course Name", text: $name)
                        TextField("Course Code", text: $code)
                        TextField("Semester", text: $semester)
                        Picker("Notification Type", selection: $notificationType) {
                            Text("Question").tag(NotificationType.question)
                            Text("Snippet").tag(NotificationType.snippet)
                            Text("Mixed").tag(NotificationType.mixed)
                        }
                        Picker("Difficulty", selection: $difficulty) {
                            Text("Easy").tag(Difficulty.easy as Difficulty?)
                            Text("Medium").tag(Difficulty.medium as Difficulty?)
                            Text("Hard").tag(Difficulty.hard as Difficulty?)
                        }
                    }
                    
                    Section(header: Text("Documents")) {
                        if let document = course.documents.first { // Assuming only one document for now
                            HStack {
                                Text(document.title)
                                Spacer()
                                Button(role: .destructive) {
                                    confirmDeleteDocument(document: document)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .alert(item: $documentToDelete) { document in
                                    Alert(
                                        title: Text("Delete Document"),
                                        message: Text("Are you sure you want to delete '\(document.title)'? This action cannot be undone."),
                                        primaryButton: .destructive(Text("Delete"), action: {
                                            deleteDocument(document: document)
                                        }),
                                        secondaryButton: .cancel({
                                            self.documentToDelete = nil
                                        })
                                    )
                                }
                                
                            }
                        } else {
                            Text("No documents attached.")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Add/Replace Document") {
                            showingFilePicker = true
                        }
                        if selectedFileURL != nil {
                            VStack(alignment: .leading) {
                                Text("Selected file: \(selectedFileURL?.lastPathComponent ?? "")")
                                TextField("Document Title", text: $documentTitle)
                            }
                        }
                        if isUploading {
                            ProgressView("Uploading...")
                        }
                        if let error = uploadError {
                            Text("Upload Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Edit Course")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            updateCourse()
                            if selectedFileURL != nil {
                                uploadNewDocument()
                            }
                        }
                        .disabled(isUploading || isDeletingDocument)
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
                case .success(let files):
                    if let fileURL = files.first {
                        selectedFileURL = fileURL
                        documentTitle = fileURL.deletingPathExtension().lastPathComponent
                        print("Selected file for upload: \(fileURL)")
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    let previewCourses = exampleCourses
    return EditCourseView(course: previewCourses.first!)
}
