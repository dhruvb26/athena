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

    private let osQuestions = [
        (
            question: "What is a process in Operating Systems?",
            options: [
                "A program in execution",
                "A file on disk",
                "A network connection",
                "A hardware component",
            ],
            correctAnswer: 0
        ),
        (
            question: "Which scheduling algorithm is non-preemptive?",
            options: [
                "Round Robin",
                "First Come First Served",
                "Shortest Remaining Time First",
                "Priority Scheduling",
            ],
            correctAnswer: 1
        ),
        (
            question: "What is thrashing in OS?",
            options: [
                "CPU overload",
                "Network congestion",
                "Excessive page faults",
                "Disk fragmentation",
            ],
            correctAnswer: 2
        ),
        (
            question: "What is the purpose of virtual memory?",
            options: [
                "To increase CPU speed",
                "To extend physical memory using disk space",
                "To improve network performance",
                "To optimize file storage",
            ],
            correctAnswer: 1
        ),
    ]

    private init() {
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

    func scheduleQuizNotification() {
        let randomQuestion = osQuestions.randomElement()!
        let questionText = randomQuestion.question
        let options = randomQuestion.options

        let optionsText = options.enumerated().map { index, option in
            "\(Character(UnicodeScalar(65 + index)!)). \(option)"
        }.joined(separator: "\n")

        let content = """
        OS Quiz Time! 🤓

        \(questionText)

        \(optionsText)
        """

        notificationManager.scheduleInteractiveNotification(
            title: "Test Your OS Knowledge!",
            body: content,
            categoryIdentifier: "os_quiz",
            timeInterval: 30,
            repeats: false
        )
    }
}
