//
//  Course.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/29/25.
//

import Foundation
import FirebaseFirestore

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
    
    var id: String {
        return docID ?? UUID().uuidString
    }
}

let exampleCourses: [Course] = [
    Course(
        name: "Principles of Mobile Computing",
        code: "CSE335",
        semester: "Spring 2025",
        notificationType: .question,
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
            )
        ]
    )
]

