//
//  CourseManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/11/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Logging

class CourseManager: ObservableObject {
    private let db = FirestoreManager().db
    private let storage = Storage.storage()
    private let storageRef = Storage.storage().reference()
    private let userId = Auth.auth().currentUser?.uid
    private let logger = Logger(label: "athena.CourseManager")

    @Published var courseDocuments: [Document] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func saveCourseToDB(_ course: Course, completion: @escaping () -> Void) {
        db.collection("courses").document(course.id).setData(course.firestoreRepresentation()) {
            error in
            if let error {
                self.logger.error("Failed to save user: \(error.localizedDescription)")
            } else {
                self.logger.info("User saved to Firestore.")
            }
            completion()
        }
    }

    func deleteCourseFromDB(_ course: Course) {
        guard let id = course.docID else { return }

        db.collection("courses").document(id).delete { error in
            if let error {
                self.logger.error("Failed to delete: \(error.localizedDescription)")
            } else {
                self.logger.info("Course deleted")
            }
        }
    }

    func updateCourseInDB(
        _ courseID: String, _ fields: [String: Any], completion: ((Error?) -> Void)? = nil
    ) {
        let courseRef = db.collection("courses").document(courseID)

        courseRef.updateData(fields) { error in
            if let error {
                self.logger.error("Failed to update course: \(error.localizedDescription)")
                completion?(error)
            } else {
                self.logger.info("Course updated successfully")
                completion?(nil)
            }
        }
    }

    func uploadDocumentToStorage(_ title: String, _ url: URL, _ course: Course, completion _: @escaping () -> Void) {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Could not access the selected file.")
            return
        }

        do {
            let fileData = try Data(contentsOf: url)
            let docRef = storageRef.child("docs/\(title)")

            let courseID = course.docID ?? ""

            docRef.putData(fileData, metadata: nil) { _, error in
                url.stopAccessingSecurityScopedResource()

                if let error {
                    self.logger.error("Error uploading document: \(error.localizedDescription)")
                    return
                }

                docRef.downloadURL { [weak self] url, error in

                    if let error {
                        self?.logger.error(
                            "Error getting download URL: \(error.localizedDescription)")
                        return
                    }

                    if let downloadURL = url?.absoluteString {
                        self?.logger.info("Document uploaded successfully.")

                        // new document object
                        let newDocument = Document(title: title, url: downloadURL)

                        // get the current course to access its documents
                        self?.db.collection("courses").document(courseID).getDocument {
                            snapshot, error in
                            if let error {
                                self?.logger.error(
                                    "Error fetching course: \(error.localizedDescription)")
                                return
                            }

                            if let data = snapshot?.data(),
                               var existingDocuments = data["documents"] as? [[String: Any]]
                            {
                                // append new document to existing documents
                                existingDocuments.append(newDocument.firestoreRepresentation())

                                // update the course with new documents array
                                self?.updateCourseInDB(
                                    courseID,
                                    ["documents": existingDocuments]
                                ) { error in
                                    if let error {
                                        self?.logger.error(
                                            "Error updating course documents: \(error.localizedDescription)"
                                        )
                                    } else {
                                        self?.logger.info("Course documents updated successfully")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            url.stopAccessingSecurityScopedResource()
            logger.error("Error reading file data: \(error.localizedDescription)")
        }
    }

    func deleteDocumentFromStorage(_ course: Course, _ document: Document, completion: @escaping () -> Void) {
        guard let courseId = course.docID else { return }

        db.collection("courses").document(courseId).getDocument {
            documentSnapshot, error in
            if let error {
                self.errorMessage = error.localizedDescription
                return
            }

            guard let documentSnapshot, documentSnapshot.exists,
                  var courseData = try? documentSnapshot.data(as: Course.self)
            else {
                return
            }

            // filter out the document with matching id
            courseData.documents = courseData.documents.filter { $0.id != document.id }

            // update the course with the filtered documents array
            do {
                try self.db.collection("courses").document(courseId).setData(
                    from: courseData, merge: true
                ) { error in
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }

                    // Now delete the file from storage if URL exists
                    if let fileURL = document.url {
                        let ref = self.storage.reference(forURL: fileURL)
                        ref.delete { error in
                            self.isLoading = false
                            if let error {
                                self.errorMessage = error.localizedDescription
                            } else {
                                completion()
                            }
                        }
                    } else {
                        self.isLoading = false
                        completion()
                    }
                }
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    @MainActor
    func loadDocumentsFromStorage(_ course: Course) async {
        isLoading = true
        errorMessage = nil

        do {
            if let courseId = course.docID {
                let docSnapshot = try await db.collection("courses").document(courseId)
                    .getDocument()

                if docSnapshot.exists,
                   let updatedCourse = try? docSnapshot.data(as: Course.self)
                {
                    courseDocuments = updatedCourse.documents
                } else {
                    courseDocuments = course.documents // fallback to local
                }
            } else {
                courseDocuments = course.documents // fallback if docID is nil
            }
        } catch {
            errorMessage = "Error loading documents: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
