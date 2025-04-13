//
//  LibraryViewModel.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var groupingOption: GroupingOption = .semester
    @Published var showingAddCourse = false
    @Published var showingOptions = false
    @Published var selectedCourse: Course?
    private let db = FirestoreManager().db
    private let currentUserId = Auth.auth().currentUser?.uid

    @Published var firestoreCourses: [Course] = []

    enum GroupingOption: String, CaseIterable, Identifiable {
        case alphabetical = "Alphabetical"
        case semester = "Semester"
        var id: String { rawValue }
    }

    init() {
        Task {
            await fetchCourses()
            setupFirestoreListener()
        }
    }

    private func setupFirestoreListener() {
        guard let userId = currentUserId else { return }

        db.collection("courses")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("🔥 Error listening for course updates: \(error.localizedDescription)")
                    return
                }

                guard let snapshot else { return }

                do {
                    firestoreCourses = try snapshot.documents.compactMap {
                        try $0.data(as: Course.self)
                    }
                } catch {
                    print("🔥 Error decoding courses: \(error.localizedDescription)")
                }
            }
    }

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            firestoreCourses
        } else {
            firestoreCourses.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var groupedCourses: [String: [Course]] {
        if groupingOption == .alphabetical {
            Dictionary(grouping: filteredCourses) { course in
                String(course.name.prefix(1)).uppercased()
            }
        } else {
            Dictionary(grouping: filteredCourses) { course in
                course.semester
            }
        }
    }

    var sortedGroupKeys: [String] {
        let keys = groupedCourses.keys.sorted()
        return groupingOption == .alphabetical ? keys : keys.sorted {
            let num1 = Int($0.components(separatedBy: " ").last ?? "0") ?? 0
            let num2 = Int($1.components(separatedBy: " ").last ?? "0") ?? 0
            return num1 < num2
        }
    }

    func fetchCourses() async {
        guard let userId = currentUserId else { return }

        do {
            let snapshot = try await db.collection("courses")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            firestoreCourses = try snapshot.documents.compactMap {
                try $0.data(as: Course.self)
            }
        } catch {
            print("🔥 Error fetching courses: \(error.localizedDescription)")
        }
    }

    func deleteCourse(_ course: Course) {
        guard let id = course.docID else { return }

        db.collection("courses").document(id).delete { error in
            if let error {
                print("❌ Failed to delete: \(error.localizedDescription)")
            } else {
                print("🗑️ Course deleted: \(course.name)")
                Task { await self.fetchCourses() }
            }
        }
    }
}
