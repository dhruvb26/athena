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

    @MainActor
    func saveCourseToDB(_ course: Course) async {
        isLoading = true

        do {
            let docRef = db.collection("courses").document(course.id)
            try await docRef.setData(course.firestoreRepresentation())

            let docSnapshot = try await docRef.getDocument()
            if let savedCourse = try? docSnapshot.data(as: Course.self) {
                userCourses.append(savedCourse)
                // logger.info("Course saved to Firestore successfully")
            } else {
                logger.error("Failed to decode saved course data")
            }

        } catch {
            logger.error("Failed to save course: \(error.localizedDescription)")
        }

        isLoading = false
    }

    @MainActor
    func deleteCourseFromDB(_ course: Course) {
        guard let id = course.docID else {
            logger.error("Failed to delete course: Invalid course ID")
            return
        }

        isLoading = true

        db.collection("courses").document(id).delete { [weak self] error in
            guard let self else { return }

            isLoading = false
            if let error {
                logger.error("Failed to delete course: \(error.localizedDescription)")
            } else {
                userCourses.removeAll { $0.id == course.id }
                // logger.info("Course deleted successfully")
            }
        }
    }

    @MainActor
    func updateCourseInDB(_ courseID: String, _ fields: [String: Any]) async {
        isLoading = true
        let courseRef = db.collection("courses").document(courseID)

        do {
            try await courseRef.updateData(fields)

            if let index = userCourses.firstIndex(where: { $0.id == courseID }) {
                // Get the updated course data
                let updatedDoc = try await courseRef.getDocument()
                if let updatedCourse = try? updatedDoc.data(as: Course.self) {
                    userCourses[index] = updatedCourse
                }
            }

            // logger.info("Course updated successfully")
        } catch {
            logger.error("Failed to update course: \(error.localizedDescription)")
        }

        isLoading = false
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

    func loadCoursesForUser(_ userId: String) async -> [String] {
        isLoading = true
        var courseIds: [String] = []

        do {
            let snapshot = try await db.collection("courses")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            userCourses = try snapshot.documents.compactMap {
                let course = try $0.data(as: Course.self)
                courseIds.append(course.id)
                return course
            }

            isLoading = false

        } catch {
            logger.error("Error fetching courses for user: \(error.localizedDescription)")
            isLoading = false
        }

        return courseIds
    }

    @MainActor
    func uploadDocumentToStorage(_ title: String, _ url: URL, _ course: Course) async throws {
        isLoading = true

        // Request access to security-scoped file URL
        guard url.startAccessingSecurityScopedResource() else {
            isLoading = false
            logger.error("Could not access the selected file")
            throw NSError(
                domain: "FileAccessError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not access the selected file"]
            )
        }

        defer {
            // Always stop access when done
            url.stopAccessingSecurityScopedResource()
        }

        do {
            // Access the file data only inside the security scope
            let fileData = try Data(contentsOf: url)
            let docRef = storageRef.child("docs/\(title)")
            let courseID = course.docID ?? ""

            _ = try await docRef.putDataAsync(fileData)
            let downloadURL = try await docRef.downloadURL().absoluteString

            // logger.info("Document uploaded successfully")
            let newDocument = Document(title: title, url: downloadURL)

            // Add document processing here
            let documentProcessor = DocumentProcessor()
            await documentProcessor.processDocument(downloadURL, course)

            let snapshot = try await db.collection("courses").document(courseID).getDocument()

            if let data = snapshot.data(),
               var existingDocuments = data["documents"] as? [[String: Any]]
            {
                existingDocuments.append(newDocument.firestoreRepresentation())
                await updateCourseInDB(courseID, ["documents": existingDocuments])
                // logger.info("Course documents updated successfully")
            } else {
                logger.error("Failed to process course documents")
                throw NSError(
                    domain: "DocumentProcessError", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to process course documents"]
                )
            }

        } catch {
            logger.error("Error in document upload process: \(error.localizedDescription)")
            throw error
        }

        isLoading = false
    }

    @MainActor
    func deleteDocumentFromStorage(_ course: Course, _ document: Document) async throws {
        isLoading = true

        guard let courseId = course.docID else {
            isLoading = false
            logger.error("Invalid course ID while attempting to delete document")
            throw NSError(
                domain: "CourseIDError", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid course ID"]
            )
        }

        do {
            let documentSnapshot = try await db.collection("courses").document(courseId)
                .getDocument() // This function should be marked with 'async'

            guard documentSnapshot.exists,
                  var courseData = try? documentSnapshot.data(as: Course.self)
            else {
                isLoading = false
                logger.error("Failed to fetch or decode course data")
                throw NSError(
                    domain: "CourseDataError", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to fetch or decode course data"]
                )
            }

            courseData.documents = courseData.documents.filter { $0.id != document.id }

            try await db.collection("courses").document(courseId).setData(
                from: courseData, merge: true)

            if let fileURL = document.url {
                let ref = storage.reference(forURL: fileURL)
                try await ref.delete()
                // logger.info("Document deleted successfully")
            } else {
                // logger.info("Document reference updated successfully")
            }
        } catch {
            logger.error("Error in document deletion process: \(error.localizedDescription)")
            throw error
        }

        isLoading = false
    }

    @MainActor
    func loadDocumentsFromStorage(_ course: Course) async {
        do {
            isLoading = true

            guard let courseId = course.docID else {
                courseDocuments = course.documents
                // logger.info("Using local course documents (no course ID)")
                return
            }

            let docSnapshot = try await db.collection("courses").document(courseId).getDocument()

            if docSnapshot.exists,
               let updatedCourse = try? docSnapshot.data(as: Course.self)
            {
                courseDocuments = updatedCourse.documents
                // logger.info("Documents loaded successfully from Firestore")
            } else {
                courseDocuments = course.documents
                // logger.info("Using local course documents (no Firestore data)")
            }
        } catch {
            logger.error("Error loading documents: \(error.localizedDescription)")
            courseDocuments = course.documents
        }

        isLoading = false
    }
}
