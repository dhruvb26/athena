//
//  CourseAddViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

class CourseAddViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadError: Error?

    private let storageRef = Storage.storage().reference()
    private let firestore = Firestore.firestore()

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func uploadCourse(
        name: String,
        code: String,
        semester: String,
        notificationType: NotificationType,
        difficulty: Difficulty?,
        documentTitle: String,
        selectedFileURL: URL?,
        completion: @escaping () -> Void
    ) {
        guard let userId = currentUserId else {
            uploadError = NSError(
                domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]
            )
            return
        }

        if let fileURL = selectedFileURL {
            uploadWithDocument(
                fileURL: fileURL,
                title: documentTitle,
                courseData: (name, code, semester, notificationType, difficulty, userId),
                completion: completion
            )
        } else {
            saveCourseToFirestore(
                name: name, code: code, semester: semester,
                notificationType: notificationType, difficulty: difficulty,
                document: nil, userId: userId,
                completion: completion
            )
        }
    }

    private func uploadWithDocument(
        fileURL: URL,
        title: String,
        courseData: (String, String, String, NotificationType, Difficulty?, String),
        completion: @escaping () -> Void
    ) {
        isUploading = true

        guard fileURL.startAccessingSecurityScopedResource() else {
            uploadError = NSError(
                domain: "FileAccessError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not access the selected file."]
            )
            isUploading = false
            return
        }

        do {
            let fileData = try Data(contentsOf: fileURL)
            let docRef = storageRef.child("docs/\(title)")

            docRef.putData(fileData, metadata: nil) { _, error in
                fileURL.stopAccessingSecurityScopedResource()
                self.isUploading = false

                if let error {
                    self.uploadError = error
                    self.saveCourseToFirestore(
                        name: courseData.0, code: courseData.1, semester: courseData.2,
                        notificationType: courseData.3, difficulty: courseData.4,
                        document: nil, userId: courseData.5,
                        completion: completion
                    )
                    return
                }

                docRef.downloadURL { url, error in
                    if let error {
                        self.uploadError = error
                        self.saveCourseToFirestore(
                            name: courseData.0, code: courseData.1, semester: courseData.2,
                            notificationType: courseData.3, difficulty: courseData.4,
                            document: nil, userId: courseData.5,
                            completion: completion
                        )
                        return
                    }

                    let document = Document(title: title, url: url?.absoluteString ?? "")
                    self.saveCourseToFirestore(
                        name: courseData.0, code: courseData.1, semester: courseData.2,
                        notificationType: courseData.3, difficulty: courseData.4,
                        document: document, userId: courseData.5,
                        completion: completion
                    )
                }
            }
        } catch {
            fileURL.stopAccessingSecurityScopedResource()
            uploadError = error
            isUploading = false
        }
    }

    private func saveCourseToFirestore(
        name: String,
        code: String,
        semester: String,
        notificationType: NotificationType,
        difficulty: Difficulty?,
        document: Document?,
        userId: String,
        completion: @escaping () -> Void
    ) {
        let newCourse = Course(
            name: name,
            code: code,
            semester: semester,
            notificationType: notificationType,
            difficulty: difficulty,
            documents: document != nil ? [document!] : [],
            userId: userId
        )

        do {
            _ = try firestore.collection("courses").addDocument(from: newCourse) { error in
                if let error {
                    self.uploadError = error
                } else {
                    print("✅ Course saved to Firestore")
                    completion()
                }
            }
        } catch {
            uploadError = error
        }
    }
}
