//
//  QuizItemManager.swift
//  Athena
//
//  Created by Kanav Gupta on 4/12/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import Logging

class QuizItemManager: ObservableObject {
    private let db = Firestore.firestore()
    private let userId = Auth.auth().currentUser?.uid
    private let logger = Logger(label: "athena.QuizItemManager")

    func saveQuizItemToDB(_ quizItem: QuizItem) async throws {
        do {
            try await db.collection("quizItems").document(quizItem.id).setData(
                quizItem.firestoreRepresentation())
            // logger.info("Quiz item saved to Firestore.")
        } catch {
            logger.error("Failed to save quiz item: \(error.localizedDescription)")
            throw error
        }
    }

    func updateQuizItem(quizItemID: String, fields: [String: Any]) async throws {
        let quizItemRef = db.collection("quizItems").document(quizItemID)

        do {
            try await quizItemRef.updateData(fields)
            // logger.info("Quiz item updated successfully")
        } catch {
            logger.error("Failed to update quiz item: \(error.localizedDescription)")
            throw error
        }
    }

    func markQuizItemAsScheduled(_ documentId: String) async throws {
        do {
            try await db.collection("quizItems").document(documentId).updateData([
                "scheduled": true,
            ])
            // logger.info("Marked quiz item as scheduled")
        } catch {
            logger.error("Error updating scheduled status: \(error.localizedDescription)")
            throw error
        }
    }

    func recordAnswerIndex(_ documentId: String, _ index: Int) async throws {
        do {
            try await db.collection("quizItems").document(documentId).updateData([
                "recordedAnswerIndex": index,
                "answered": true,
            ])
            // logger.info("Recorded answer index successfully")
        } catch {
            logger.error("Error recording answer index: \(error.localizedDescription)")
            throw error
        }
    }

    func loadUnscheduledQuizItems(_ userId: String) async throws -> [QuizItem] {
        var quizItems: [QuizItem] = []

        let courseManager = CourseManager()
        let courseIds = await courseManager.loadCoursesForUser(userId)

        let querySnapshot =
            try await db
                .collection("quizItems")
                .whereField("scheduled", isEqualTo: false)
                .whereField("courseId", in: courseIds)
                .getDocuments()

        for document in querySnapshot.documents {
            do {
                var data = document.data()
                data["docID"] = document.documentID
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let quizItem = try JSONDecoder().decode(QuizItem.self, from: jsonData)
                quizItems.append(quizItem)
            } catch {
                logger.error("Failed to decode QuizItem: \(error)")
            }
        }
        return quizItems
    }
}
