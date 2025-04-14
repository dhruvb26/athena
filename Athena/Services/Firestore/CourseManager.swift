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
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let storageRef = Storage.storage().reference()
    private let userId = Auth.auth().currentUser?.uid
    private let logger = Logger(label: "athena.CourseManager")

    @Published var courseDocuments: [Document] = []
    @Published var userCourses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func saveCourseToDB(_ course: Course, completion: @escaping () -> Void) {
        isLoading = true

        db.collection("courses").document(course.id).setData(course.firestoreRepresentation()) {
            error in
            self.isLoading = false
            if let error {
                self.logger.error("Failed to save course: \(error.localizedDescription)")
            } else {
                self.logger.info("Course saved to Firestore successfully")
            }

            completion()
        }
    }

    func deleteCourseFromDB(_ course: Course) {
        guard let id = course.docID else {
            logger.error("Failed to delete course: Invalid course ID")
            return
        }

        isLoading = true

        db.collection("courses").document(id).delete { error in
            self.isLoading = false
            if let error {
                self.logger.error("Failed to delete course: \(error.localizedDescription)")
            } else {
                self.logger.info("Course deleted successfully")
            }
        }
    }

    func updateCourseInDB(
        _ courseID: String, _ fields: [String: Any], completion: @escaping () -> Void
    ) {
        isLoading = true
        let courseRef = db.collection("courses").document(courseID)

        courseRef.updateData(fields) { error in
            self.isLoading = false
            if let error {
                self.logger.error("Failed to update course: \(error.localizedDescription)")
            } else {
                self.logger.info("Course updated successfully")
            }

            completion()
        }
    }

    @MainActor
    func loadCoursesFromDB() async {
        guard let userId else {
            logger.error("User ID not found. Cannot fetch courses.")
            return
        }

        isLoading = true

        do {
            let snapshot = try await db.collection("courses")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            userCourses = try snapshot.documents.compactMap {
                try $0.data(as: Course.self)
            }

            isLoading = false

        } catch {
            logger.error("Error fetching courses: \(error.localizedDescription)")
        }
    }

    func uploadDocumentToStorage(
        _ title: String, _ url: URL, _ course: Course, completion _: @escaping () -> Void
    ) {
        isLoading = true

        guard url.startAccessingSecurityScopedResource() else {
            isLoading = false
            logger.error("Could not access the selected file")
            return
        }

        do {
            let fileData = try Data(contentsOf: url)
            let docRef = storageRef.child("docs/\(title)")
            let courseID = course.docID ?? ""

            docRef.putData(fileData, metadata: nil) { _, error in
                url.stopAccessingSecurityScopedResource()

                if let error {
                    self.isLoading = false
                    self.logger.error("Error uploading document: \(error.localizedDescription)")
                    return
                }

                docRef.downloadURL { [weak self] url, error in
                    guard let self else { return }

                    if let error {
                        isLoading = false
                        logger.error(
                            "Error getting download URL: \(error.localizedDescription)")
                        return
                    }

                    guard let downloadURL = url?.absoluteString else {
                        isLoading = false
                        logger.error("Failed to get download URL")
                        return
                    }

                    logger.info("Document uploaded successfully")
                    let newDocument = Document(title: title, url: downloadURL)

                    db.collection("courses").document(courseID).getDocument {
                        snapshot, error in
                        if let error {
                            self.isLoading = false
                            self.logger.error(
                                "Error fetching course: \(error.localizedDescription)")
                            return
                        }

                        if let data = snapshot?.data(),
                           var existingDocuments = data["documents"] as? [[String: Any]]
                        {
                            existingDocuments.append(newDocument.firestoreRepresentation())

                            self.updateCourseInDB(courseID, ["documents": existingDocuments]) {
                                self.isLoading = false
                                if let error {
                                    self.logger.error(
                                        "Error updating course documents: \(error.localizedDescription)"
                                    )
                                } else {
                                    self.logger.info("Course documents updated successfully")
                                }
                            }
                        } else {
                            self.isLoading = false
                            self.logger.error("Failed to process course documents")
                        }
                    }
                }
            }
        } catch {
            url.stopAccessingSecurityScopedResource()
            isLoading = false
            logger.error("Error reading file data: \(error.localizedDescription)")
        }
    }

    func deleteDocumentFromStorage(
        _ course: Course, _ document: Document, completion: @escaping () -> Void
    ) {
        isLoading = true

        guard let courseId = course.docID else {
            isLoading = false
            logger.error("Invalid course ID while attempting to delete document")
            return
        }

        db.collection("courses").document(courseId).getDocument { documentSnapshot, error in
            if let error {
                self.isLoading = false
                self.logger.error("Error fetching course: \(error.localizedDescription)")
                return
            }

            guard let documentSnapshot, documentSnapshot.exists,
                  var courseData = try? documentSnapshot.data(as: Course.self)
            else {
                self.isLoading = false
                self.logger.error("Failed to fetch or decode course data")
                return
            }

            courseData.documents = courseData.documents.filter { $0.id != document.id }

            do {
                try self.db.collection("courses").document(courseId).setData(
                    from: courseData, merge: true
                ) { error in
                    if let error {
                        self.isLoading = false
                        self.logger.error("Error updating course: \(error.localizedDescription)")
                        return
                    }

                    if let fileURL = document.url {
                        let ref = self.storage.reference(forURL: fileURL)
                        ref.delete { error in
                            self.isLoading = false
                            if let error {
                                self.logger.error(
                                    "Error deleting file from storage: \(error.localizedDescription)"
                                )
                            } else {
                                self.logger.info("Document deleted successfully")
                                completion()
                            }
                        }
                    } else {
                        self.isLoading = false
                        self.logger.info("Document reference updated successfully")
                        completion()
                    }
                }
            } catch {
                self.isLoading = false
                self.logger.error("Error encoding course data: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func loadDocumentsFromStorage(_ course: Course) async {
        do {
            isLoading = true

            guard let courseId = course.docID else {
                courseDocuments = course.documents
                logger.info("Using local course documents (no course ID)")
                return
            }

            let docSnapshot = try await db.collection("courses").document(courseId).getDocument()

            if docSnapshot.exists,
               let updatedCourse = try? docSnapshot.data(as: Course.self)
            {
                courseDocuments = updatedCourse.documents
                logger.info("Documents loaded successfully from Firestore")
            } else {
                courseDocuments = course.documents
                logger.info("Using local course documents (no Firestore data)")
            }
        } catch {
            logger.error("Error loading documents: \(error.localizedDescription)")
            courseDocuments = course.documents
        }

        isLoading = false
    }
}
