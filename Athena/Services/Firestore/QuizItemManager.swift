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

    func saveQuizItemToDB(_ quizItem: QuizItem, completion: @escaping () -> Void) {
        db.collection("quizItems").document(quizItem.id).setData(quizItem.firestoreRepresentation()) {
            error in
            if let error {
                self.logger.error("Failed to save quiz item: \(error.localizedDescription)")
            } else {
                self.logger.info("Quiz item saved to Firestore.")
            }
            completion()
        }
    }

    func updateQuizItem(
        _ quizItemID: String, _ fields: [String: Any], completion: ((Error?) -> Void)? = nil
    ) {
        let quizItemRef = db.collection("quizItems").document(quizItemID)

        quizItemRef.updateData(fields) { error in
            if let error {
                self.logger.error("Failed to update quiz item: \(error.localizedDescription)")
                completion?(error)
            } else {
                self.logger.info("Quiz item updated successfully")
                completion?(nil)
            }
        }
    }

    func markQuizItemAsScheduled(documentId: String) {
        db.collection("quizItems").document(documentId).updateData([
            "scheduled": true,
        ]) { error in
            if let error {
                self.logger.error("Error updating scheduled status: \(error.localizedDescription)")
            } else {
                self.logger.info("Marked quiz item as scheduled")
            }
        }
    }
}
