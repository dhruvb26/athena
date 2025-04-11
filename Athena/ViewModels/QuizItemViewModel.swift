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

    func fetchSnippetsAndScheduleNotifications() {
        isLoading = true

        snippets.removeAll()

        firestore.collection("quizItems")
            .whereField("type", isEqualTo: QuizItemType.snippet.rawValue)
            .whereField("scheduled", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                isLoading = false

                if let error {
                    loadError = error
                    print("Error fetching snippets: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No unscheduled snippet documents found")
                    return
                }

                for document in documents {
                    do {
                        var snippet = try document.data(as: QuizItem.self)
                        snippets.append(snippet)

                        // Schedule a notification for this snippet
                        scheduleNotificationForSnippet(snippet)

                        // Mark the snippet as scheduled
                        markSnippetAsScheduled(documentId: document.documentID)
                    } catch {
                        print("Error decoding snippet: \(error.localizedDescription)")
                    }
                }

                print(
                    "✅ Fetched \(snippets.count) unscheduled snippets and scheduled notifications"
                )
            }
    }

    private func scheduleNotificationForSnippet(_ snippet: QuizItem) {
        let randomTime = TimeInterval.random(in: 60 ... 120) // Between 1 minute and 2 minutes

        let tagString = snippet.tags.isEmpty ? "" : " #\(snippet.tags.joined(separator: " #"))"

        notificationManager.scheduleBasicNotification(
            title: "\(snippet.title)",
            body: "\(snippet.body)",
            timeInterval: randomTime,
            repeats: false
        )
    }

    private func markSnippetAsScheduled(documentId: String) {
        firestore.collection("quizItems").document(documentId).updateData([
            "scheduled": true,
        ]) { error in
            if let error {
                print("Error updating scheduled status: \(error.localizedDescription)")
            } else {
                print("✅ Marked snippet as scheduled")
            }
        }
    }
}
