//
//  UserManager.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/11/25.
//

import FirebaseAuth
import FirebaseFirestore
import Logging

class UserManager {
    private let db = FirestoreManager().db
    private let logger = Logger(label: "athena.UserManager")

    func saveUserToDB(_ user: User) {
        let data: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? "no-email",
        ]

        db.collection("users").document(user.uid).setData(data) { error in
            if let error {
                self.logger.error("Failed to save user: \(error.localizedDescription)")
            } else {
                self.logger.info("User saved to Firestore")
            }
        }
    }
}
