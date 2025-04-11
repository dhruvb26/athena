//
//  QuizItemViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/11/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class QuizItemViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadError: Error?

    private let firestore = Firestore.firestore()

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    func addQuizItem(
        title: String,
        body: String,
        type: QuizItemType,
        courseId: String,
        tags: [String],
        options: [String]? = nil,
        correctAnswerIndex: Int? = nil,
        completion: @escaping () -> Void
    ) {
        guard let userId = currentUserId else {
            uploadError = NSError(
                domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"]
            )
            return
        }

        isUploading = true

        let newQuizItem = QuizItem(
            title: title,
            body: body,
            type: type,
            courseId: courseId,
            tags: tags,
            options: type == .question ? options : nil,
            correctAnswerIndex: type == .question ? correctAnswerIndex : nil,
            answered: type == .question ? false : nil,
            recordedAnswerIndex: nil
        )

        do {
            _ = try firestore.collection("quizItems").addDocument(from: newQuizItem) {
                [weak self] error in
                self?.isUploading = false

                if let error {
                    self?.uploadError = error
                } else {
                    print("✅ Quiz Item saved to Firestore")
                    completion()
                }
            }
        } catch {
            isUploading = false
            uploadError = error
        }
    }
}
