//
//  AddCourseView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct AddCourseView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var courseManager: CourseManager

    @State private var name = ""
    @State private var code = ""
    @State private var semester = ""
    @State private var documentTitle = ""
    @State private var notificationType: NotificationType = .question
    @State private var difficulty: Difficulty = .easy
    @State private var isUploadingOverlayVisible = false

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
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
                    .navigationTitle("New Course")
                    .navigationBarTitleDisplayMode(.inline)

                    Button {
                        isUploadingOverlayVisible = true

                        let course = Course(
                            name: name,
                            code: code,
                            semester: semester,
                            notificationType: notificationType,
                            difficulty: difficulty,
                            documents: [],
                            userId: authViewModel.getAuthUserId()
                        )

                        Task {
                            await courseManager.saveCourseToDB(course)
                            isUploadingOverlayVisible = false
                            dismiss()
                        }

                    } label: {
                        Text("Confirm")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.primaryPurple)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                    }
                    .padding(15)
                }
                .tint(Color.secondaryPurple)
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

#Preview {
    AddCourseView()
        .environmentObject(CourseManager())
}
