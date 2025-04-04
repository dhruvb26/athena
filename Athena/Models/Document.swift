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
    var dateAdded: Date
}

extension Document { // represents the Firestore object
    func firestoreRepresentation() -> [String: Any] {
        return [
            "id": id.uuidString,
            "title": title,
            "url": url ?? "",
            "dateAdded": dateAdded
        ]
    }
}
