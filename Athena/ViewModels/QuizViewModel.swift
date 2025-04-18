//
//  QuizViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/18/25.
//

import FirebaseAuth
import Foundation
import Logging

class QuizViewModel {
    private let notificationManager = NotificationManager.shared
    private let quizItemManager = QuizItemManager()
    private let userId = Auth.auth().currentUser?.uid
    private let logger = Logger(label: "athena.QuizViewModel")

    func scheduleQuizItemsFromDb() async throws {
        guard let userId else {
            throw NSError(domain: "QuizViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let quizItems = try await quizItemManager.loadUnscheduledQuizItems(userId)

        for quizItem in quizItems {
            do {
                if quizItem.type == .snippet {
                    let timeForItem = Date().addingTimeInterval(120)

                    notificationManager.scheduleBasicNotification(
                        title: quizItem.title,
                        body: quizItem.body,
                        date: timeForItem
                    )
                }

                else if quizItem.type == .question {
                    var allNotificationActions: [NotificationAction] = []

                    // create notification actions
                    if let options = quizItem.options {
                        for opt in options {
                            let action = NotificationAction(
                                identifier: "option_\(opt)",
                                title: opt,
                                options: [],
                                handler: { [weak self] _ in
                                    if let optionIndex = options.firstIndex(of: opt) {
                                        Task {
                                            try? await self?.quizItemManager.recordAnswerIndex(quizItem.id, optionIndex)
                                        }
                                    }
                                }
                            )
                            allNotificationActions.append(action)
                        }

                        let category = NotificationCategory(
                            identifier: "\(quizItem.id)",
                            actions: allNotificationActions
                        )

                        notificationManager.registerCategory(category)

                        let timeForItem = Date().addingTimeInterval(120)

                        notificationManager.scheduleInteractiveNotification(
                            title: quizItem.title,
                            body: quizItem.body,
                            categoryIdentifier: category.identifier,
                            date: timeForItem
                        )
                    }
                }

                try await quizItemManager.markQuizItemAsScheduled(quizItem.id)
            } catch {
                logger.error("Failed to schedule quiz item \(quizItem.id): \(error.localizedDescription)")
                continue
            }
        }
    }
}
