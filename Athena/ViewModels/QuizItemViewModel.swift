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
    @Published var snippets: [QuizItem] = []
    @Published var isLoading = false
    @Published var loadError: Error?

    private let firestore = Firestore.firestore()
    private let notificationManager = NotificationManager.shared

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        // We'll no longer register a static category since we'll create dynamic ones per question
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
            scheduled: false,
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

    func fetchUnscheduledQuizItemsAndScheduleNotifications() {
        isLoading = true

        snippets.removeAll()

        firestore.collection("quizItems")
            .whereField("scheduled", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                isLoading = false

                if let error {
                    loadError = error
                    print("Error fetching quiz items: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No unscheduled quiz items found")
                    return
                }

                for document in documents {
                    do {
                        var quizItem = try document.data(as: QuizItem.self)
                        snippets.append(quizItem)

                        // Schedule a notification based on quiz item type
                        scheduleNotificationForQuizItem(quizItem)

                        // Mark the quiz item as scheduled
                        markQuizItemAsScheduled(documentId: document.documentID)
                    } catch {
                        print("Error decoding quiz item: \(error.localizedDescription)")
                    }
                }

                print(
                    "✅ Fetched \(snippets.count) unscheduled quiz items and scheduled notifications"
                )
            }
    }

    private func scheduleNotificationForQuizItem(_ quizItem: QuizItem) {
        // Random time between 1 minute and 2 minutes
        let randomTime = TimeInterval.random(in: 60 ... 120)
        let tagString = quizItem.tags.isEmpty ? "" : " #\(quizItem.tags.joined(separator: " #"))"

        switch quizItem.type {
        case .snippet:
            notificationManager.scheduleBasicNotification(
                title: "\(quizItem.title)",
                body: "\(quizItem.body)",
                timeInterval: randomTime,
                repeats: false
            )
        case .question:
            // For questions, create dynamic notification actions for each option
            if let options = quizItem.options, let correctAnswerIndex = quizItem.correctAnswerIndex {
                let categoryId = "QUIZ_QUESTION_\(quizItem.id ?? UUID().uuidString)"

                // Create an action for each option
                var actions: [NotificationAction] = []

                for (index, option) in options.enumerated() {
                    let isCorrect = index == correctAnswerIndex
                    let actionId = "OPTION_\(index)_\(isCorrect ? "CORRECT" : "INCORRECT")"

                    let action = NotificationAction(
                        identifier: actionId,
                        title: option,
                        options: [],
                        handler: { [weak self] _ in
                            print(
                                "User selected option \(index): \(isCorrect ? "correct" : "incorrect")"
                            )
                            // Could add feedback or scoring logic here
                        }
                    )

                    actions.append(action)
                }

                // Register the dynamic category for this specific question
                let category = NotificationCategory(
                    identifier: categoryId,
                    actions: actions
                )

                notificationManager.registerCategory(category)

                // Schedule the notification with just the question title and body
                let userInfo: [AnyHashable: Any] = [
                    "quizItemId": quizItem.id ?? "",
                    "correctAnswerIndex": correctAnswerIndex,
                ]

                notificationManager.scheduleInteractiveNotification(
                    title: "Quiz Question: \(quizItem.title)",
                    body: quizItem.body,
                    categoryIdentifier: categoryId,
                    userInfo: userInfo,
                    timeInterval: randomTime,
                    repeats: false
                )
            } else {
                // Fallback if we don't have options or correctAnswerIndex
                notificationManager.scheduleBasicNotification(
                    title: "Quiz Question: \(quizItem.title)",
                    body: quizItem.body,
                    timeInterval: randomTime,
                    repeats: false
                )
            }
        }
    }

    private func markQuizItemAsScheduled(documentId: String) {
        firestore.collection("quizItems").document(documentId).updateData([
            "scheduled": true,
        ]) { error in
            if let error {
                print("Error updating scheduled status: \(error.localizedDescription)")
            } else {
                print("✅ Marked quiz item as scheduled")
            }
        }
    }
}
