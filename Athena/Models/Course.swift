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
    @DocumentID var docID: String?
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
        name: "Introduction to Swift",
        code: "SWIFT101",
        semester: "Fall 2024",
        notificationType: .question,
        documents: [
            Document(
                title: "Lecture Notes",
                url: "These notes cover the basics of Swift programming.",
                dateAdded: Date()
            ),
            Document(
                title: "Assignment 1",
                url: "Complete exercises on variables, constants, and control flow.",
                dateAdded: Date()
            )
        ]
    ),
    Course(
        name: "Data Structures",
        code: "CS102",
        semester: "Spring 2025",
        notificationType: .snippet,
        documents: [
            Document(
                title: "Reading Material",
                url: "Chapters 1-3 from the Data Structures textbook.",
                dateAdded: Date()
            )
        ]
    )
]

