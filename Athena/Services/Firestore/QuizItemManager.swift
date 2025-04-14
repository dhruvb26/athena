//
//  QuizItemManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/12/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import Logging

class QuizItemManager {
    private let db = Firestore.firestore()
    private let userId = Auth.auth().currentUser?.uid
    private let logger = Logger(label: "athena.QuizItemManager")

    func saveQuizItemToDB(_ quizItem: QuizItem) async throws {
        do {
            try await db.collection("quizItems").document(quizItem.id).setData(quizItem.firestoreRepresentation())
            logger.info("Quiz item saved to Firestore.")
        } catch {
            logger.error("Failed to save quiz item: \(error.localizedDescription)")
            throw error
        }
    }

    func updateQuizItem(quizItemID: String, fields: [String: Any]) async throws {
        let quizItemRef = db.collection("quizItems").document(quizItemID)

        do {
            try await quizItemRef.updateData(fields)
            logger.info("Quiz item updated successfully")
        } catch {
            logger.error("Failed to update quiz item: \(error.localizedDescription)")
            throw error
        }
    }

    func markQuizItemAsScheduled(documentId: String) async throws {
        do {
            try await db.collection("quizItems").document(documentId).updateData([
                "scheduled": true,
            ])
            logger.info("Marked quiz item as scheduled")
        } catch {
            logger.error("Error updating scheduled status: \(error.localizedDescription)")
            throw error
        }
    }
}
