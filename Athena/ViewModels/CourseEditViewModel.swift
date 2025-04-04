//
//  CourseEditViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
class CourseEditViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var isDeleting = false
    @Published var uploadError: Error?

    private let firestore = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func updateCourse(_ course: Course, name: String, code: String, semester: String, notificationType: NotificationType, difficulty: Difficulty?, completion: @escaping () -> Void) {
        guard let courseId = course.docID else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"])
            return
        }

        let updatedData: [String: Any] = [
            "name": name,
            "code": code,
            "semester": semester,
            "notificationType": notificationType.rawValue,
            "difficulty": difficulty?.rawValue as Any,
        ]

        firestore.collection("courses").document(courseId).updateData(updatedData) { error in
            if let error {
                self.uploadError = error
            } else {
                completion()
            }
        }
    }

    func uploadDocument(for course: Course, fileURL: URL, title: String, completion: @escaping () -> Void) {
        guard let _ = course.docID else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"])
            return
        }

        isUploading = true

        guard fileURL.startAccessingSecurityScopedResource() else {
            uploadError = NSError(domain: "Access", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't access file"])
            isUploading = false
            return
        }

        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: fileURL)
            let ref = storage.reference().child("docs/\(title)_\(UUID().uuidString)")
            ref.putData(data, metadata: nil) { _, error in
                self.isUploading = false

                if let error {
                    self.uploadError = error
                    return
                }

                ref.downloadURL { url, error in
                    if let error {
                        self.uploadError = error
                        return
                    }

                    guard let url else { return }
                    let document = Document(title: title, url: url.absoluteString, dateAdded: Date())
                    self.addDocumentReference(to: course, document: document, completion: completion)
                }
            }
        } catch {
            isUploading = false
            uploadError = error
        }
    }

    private func addDocumentReference(to course: Course, document: Document, completion: @escaping () -> Void) {
        guard let courseId = course.docID else { return }

        firestore.collection("courses").document(courseId).updateData([
            "documents": FieldValue.arrayUnion([document.firestoreRepresentation()]),
        ]) { error in
            if let error {
                self.uploadError = error
            } else {
                completion()
            }
        }
    }

    func deleteDocument(course: Course, document: Document, completion: @escaping () -> Void) {
        guard let courseId = course.docID else { return }
        guard let userId = currentUserId, userId == course.userId else {
            uploadError = NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not authorized to edit this course"])
            return
        }

        isDeleting = true

        let removeDocRef = {
            self.firestore.collection("courses").document(courseId).updateData([
                "documents": FieldValue.arrayRemove([document.firestoreRepresentation()]),
            ]) { error in
                self.isDeleting = false
                if let error {
                    self.uploadError = error
                } else {
                    completion()
                }
            }
        }

        if let fileURL = document.url {
            let ref = storage.reference(forURL: fileURL)
            ref.delete { error in
                if let error {
                    self.uploadError = error
                    self.isDeleting = false
                } else {
                    removeDocRef()
                }
            }
        } else {
            removeDocRef()
        }
    }
}
