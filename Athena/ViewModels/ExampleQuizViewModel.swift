//
//  ExampleQuizViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/4/25.
//

import SwiftUI
import UserNotifications

class ExampleQuizViewModel: ObservableObject {
    static let shared = ExampleQuizViewModel()
    private let notificationManager = NotificationManager.shared

    @Published var quizItems: [QuizItem] = []

    private init() {
        quizItems = exampleQuizItems.filter { $0.type == .question }
        setupNotificationCategory()
    }

    private func setupNotificationCategory() {
        let actions = [
            NotificationAction(
                identifier: "option1",
                title: "Option A",
                options: [],
                handler: { _ in print("Option 1 selected") }
            ),
            NotificationAction(
                identifier: "option2",
                title: "Option B",
                options: [],
                handler: { _ in print("Option 2 selected") }
            ),
            NotificationAction(
                identifier: "option3",
                title: "Option C",
                options: [],
                handler: { _ in print("Option 3 selected") }
            ),
            NotificationAction(
                identifier: "option4",
                title: "Option D",
                options: [],
                handler: { _ in print("Option 4 selected") }
            ),
        ]

        let category = NotificationCategory(
            identifier: "os_quiz",
            actions: actions
        )

        notificationManager.registerCategory(category)
    }

    func exampleQuizNotification() {
        guard let randomQuizItem = quizItems.randomElement(),
              let options = randomQuizItem.options
        else {
            print("No valid quiz items available")
            return
        }

        let questionText = randomQuizItem.body

        let optionsText = options.enumerated().map { index, option in
            "\(Character(UnicodeScalar(65 + index)!)). \(option)"
        }.joined(separator: "\n")

        let content = """
        \(randomQuizItem.title) 🤓

        \(questionText)

        \(optionsText)
        """

        notificationManager.scheduleInteractiveNotification(
            title: "Test Your Knowledge!",
            body: content,
            categoryIdentifier: "os_quiz",
            timeInterval: 30,
            repeats: false
        )
    }
}
