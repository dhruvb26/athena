//
//  Document.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/31/25.
//

import Foundation

struct Document: Identifiable, Codable {
    var id = UUID()
    var title: String
    var url: String?
}

// creating Firestore representation
extension Document {
    func firestoreRepresentation() -> [String: Any] {
        [
            "id": id.uuidString,
            "title": title,
            "url": url ?? "",
        ]
    }
}

let exampleDocument = Document(
    title: "Example Document", url: "https://example.com/assignment1.pdf"
)
