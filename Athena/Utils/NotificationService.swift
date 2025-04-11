// //
// //  NotificationService.swift
// //  Athena
// //
// //  Created on current date
// //

// import Foundation
// import SwiftUI
// import UserNotifications

// class NotificationService {
//     private let notificationManager = NotificationManager.shared
    
    
//     // MARK: - Database and File Operations
    
//     /// Fetch files from database and schedule notifications based on content
//     func fetchFilesAndScheduleNotifications() {
//         // Simulate fetching files from database
//         fetchFilesFromDatabase { [weak self] files in
//             guard let self = self else { return }
            
//             for file in files {
//                 // Parse each file to extract notification content
//                 self.parseFile(file: file) { title, body, date, fileId in
//                     // Schedule notification with the parsed data
//                     self.scheduleFileNotification(
//                         title: title,
//                         body: body,
//                         fileId: fileId,
//                         date: date
//                     )
//                 }
//             }
//         }
//     }
    
//     /// Placeholder: Fetch files from database
//     private func fetchFilesFromDatabase(completion: @escaping ([DatabaseFile]) -> Void) {
//         // This is a placeholder function that simulates fetching files from a database
//         // In a real implementation, this would connect to your database (Firebase, Core Data, etc.)
        
//         // Simulated asynchronous database call
//         DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//             let files: [DatabaseFile] = [
//                 DatabaseFile(id: "file1", name: "Assignment 1", path: "/documents/assignment1.pdf", dueDate: Date().addingTimeInterval(86400)),
//                 DatabaseFile(id: "file2", name: "Project Report", path: "/documents/report.docx", dueDate: Date().addingTimeInterval(172800)),
//                 DatabaseFile(id: "file3", name: "Study Notes", path: "/documents/notes.txt", dueDate: Date().addingTimeInterval(259200))
//             ]
//             completion(files)
//         }
//     }
    
//     /// Placeholder: Parse file to extract notification content
//     private func parseFile(file: DatabaseFile, completion: @escaping (String, String, Date, String) -> Void) {
//         // This is a placeholder function that simulates parsing a file
//         // In a real implementation, this would read and analyze the actual file content
        
//         // Simulate file parsing
//         let title = "Reminder: \(file.name)"
//         let body = "Your file '\(file.name)' needs attention before the deadline."
        
//         // Pass the extracted information to the completion handler
//         completion(title, body, file.dueDate, file.id)
//     }
    
    