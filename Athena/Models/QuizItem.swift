//
//  QuizItem.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/5/25.
//

import FirebaseFirestore
import Foundation

enum QuizItemType: String, Codable {
    case question
    case snippet
}

struct QuizItem: Identifiable, Codable {
    @DocumentID var docID: String?
    var title: String
    var content: String
    var type: QuizItemType
    var courseId: String
    var createdAt: Date

    // questions
    var options: [String]?
    var correctAnswerIndex: Int?
    var answered: Bool?
    var recordedAnswerIndex: Int?

    // snippets
    var topic: String?
    var tags: [String]?
    var opened: Bool?

    var id: String {
        docID ?? UUID().uuidString
    }
}

// creating Firestore representation
extension QuizItem {
    func firestoreRepresentation() -> [String: Any] {
        var representation: [String: Any] = [
            "title": title,
            "content": content,
            "type": type.rawValue,
            "courseId": courseId,
            "createdAt": createdAt,
        ]

        if type == .question, let options, let correctAnswerIndex {
            representation["options"] = options
            representation["correctAnswerIndex"] = correctAnswerIndex
            representation["answered"] = answered ?? false
            if let recordedAnswerIndex {
                representation["recordedAnswerIndex"] = recordedAnswerIndex
            }
        } else if type == .snippet {
            representation["topic"] = topic ?? ""
            representation["tags"] = tags ?? []
            representation["opened"] = opened ?? false
        }

        return representation
    }
}

let exampleQuizItems: [QuizItem] = [
    QuizItem(
        title: "Operating Systems Quiz",
        content: "What is a process in Operating Systems?",
        type: .question,
        courseId: "cse335",
        createdAt: Date(),
        options: [
            "A program in execution",
            "A file on disk",
            "A network connection",
            "A hardware component",
        ],
        correctAnswerIndex: 0
    ),

    QuizItem(
        title: "Swift Concurrency",
        content:
        "Swift's async/await feature allows you to write asynchronous code that looks like synchronous code. This makes complex operations like network requests much easier to understand and maintain.",
        type: .snippet,
        courseId: "cse335",
        createdAt: Date(),
        topic: "iOS Development",
        tags: ["Swift", "Concurrency", "Async/Await"]
    ),
]
