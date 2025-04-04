//
//  Course.swift
//  Athena
//
//  Created by Kanav Gupta on 3/29/25.
//

import FirebaseFirestore
import Foundation

enum Difficulty: String, Codable {
    case easy
    case medium
    case hard
}

enum NotificationType: String, Codable {
    case question
    case snippet
    case mixed
}

struct Course: Identifiable, Codable {
    @DocumentID var docID: String? // renamed to docID to not conflict with Firestore
    var name: String
    var code: String
    var icon: String?
    var semester: String
    var notificationType: NotificationType
    var difficulty: Difficulty?
    var documents: [Document]
    var userId: String

    var id: String {
        docID ?? UUID().uuidString
    }
}

let exampleCourses: [Course] = [
    Course(
        name: "Principles of Mobile Computing",
        code: "CSE335",
        semester: "Spring 2025",
        notificationType: .question,
        difficulty: .easy,
        documents: [
            Document(
                title: "Lecture Notes",
                url: "https://example.com/lecturenotes.pdf",
                dateAdded: Date()
            ),
            Document(
                title: "Assignment 1",
                url: "https://example.com/assignment1.pdf",
                dateAdded: Date()
            ),
        ],
        userId: "example_user_id"
    ),
]
