//
//  CourseDetailViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

@MainActor
class CourseDetailViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var documents: [Document] = []
    
    private let storage = Storage.storage()
    private let firestore = Firestore.firestore()
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    func loadDocuments(for course: Course) async {
        isLoading = true
        errorMessage = nil
        
        guard let userId = currentUserId, userId == course.userId else {
            errorMessage = "Not authorized to view this course's documents"
            isLoading = false
            return
        }
        
        do {
            // First, get the latest course data to ensure we have the most up-to-date documents
            if let courseId = course.docID {
                let docSnapshot = try await firestore.collection("courses").document(courseId).getDocument()
                if let updatedCourse = try? docSnapshot.data(as: Course.self) {
                    documents = updatedCourse.documents
                } else {
                    documents = course.documents
                }
            } else {
                documents = course.documents
            }
            isLoading = false
        } catch {
            errorMessage = "Error loading documents: \(error.localizedDescription)"
            isLoading = false
        }
    }
} 
