//
//  EditCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/3/25.
//

import FirebaseFirestore
import SwiftUI
import UniformTypeIdentifiers

struct EditCourseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var courseManager: CourseManager

    @State var course: Course
    @State private var name: String
    @State private var code: String
    @State private var semester: String
    @State private var notificationType: NotificationType
    @State private var difficulty: Difficulty
    @State private var isUploadingOverlayVisible = false

    init(course: Course) {
        _course = State(initialValue: course)
        _name = State(initialValue: course.name)
        _code = State(initialValue: course.code)
        _semester = State(initialValue: course.semester)
        _notificationType = State(initialValue: course.notificationType)
        _difficulty = State(initialValue: course.difficulty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack(spacing: 10) {
                    Form {
                        Section {
                            TextField("Course Name", text: $name)
                            TextField("Course Code", text: $code)
                            TextField("Semester", text: $semester)
                        }

                        Section {
                            Picker("Notification Type", selection: $notificationType) {
                                Text("Question").tag(NotificationType.question)
                                Text("Snippet").tag(NotificationType.snippet)
                                Text("Mixed").tag(NotificationType.mixed)
                            }
                        }

                        Section {
                            Picker("Difficulty", selection: $difficulty) {
                                Text("Easy").tag(Difficulty.easy)
                                Text("Medium").tag(Difficulty.medium)
                                Text("Hard").tag(Difficulty.hard)
                            }
                        }
                    }

                    Button {
                        isUploadingOverlayVisible = true

                        let fields: [String: Any] = [
                            "name": name,
                            "code": code,
                            "semester": semester,
                            "notificationType": notificationType.rawValue,
                            "difficulty": difficulty.rawValue,
                        ]

                        Task {
                            await courseManager.updateCourseInDB(course.id, fields)
                            isUploadingOverlayVisible = false
                            dismiss()
                        }
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.primaryPurple)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .tint(Color.secondaryPurple)
                .navigationTitle("Edit Course")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                if isUploadingOverlayVisible {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        ProgressView()
                    }
                }
            }
        }
    }
}
