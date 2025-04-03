//
//  LibraryView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI
import FirebaseFirestore

struct LibraryView: View {
    @EnvironmentObject var firestoreManager: FirestoreManager

    var db: Firestore {
        firestoreManager.db
    }

    @State private var searchText = ""
    @State private var showingOptions = false
    @State private var selectedCourse: Course?
    @State private var groupingOption: GroupingOption = .semester
    @State private var showingAddCourse: Bool = false
    @State private var courses: [Course] = []
    @FirestoreQuery(collectionPath: "courses") var firestoreCourses: [Course]


    enum GroupingOption: String, CaseIterable, Identifiable {
        case alphabetical = "Alphabetical"
        case semester = "Semester"
        var id: String { self.rawValue }
    }

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return firestoreCourses
        } else {
            return firestoreCourses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedCourses: [String: [Course]] {
        let sorted = filteredCourses

        if groupingOption == .alphabetical {
            return Dictionary(grouping: sorted) { course in
                let firstChar = course.name.prefix(1).uppercased()
                return firstChar
            }
        } else {
            return Dictionary(grouping: sorted) { course in
                return "\(course.semester)"
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

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    searchBarView

                    HStack {
                        Picker("Group by", selection: $groupingOption) {
                            ForEach(GroupingOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .accentColor(Color.primary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    courseListView

                    addToLibraryButton
                }
                .navigationTitle("Library")
            }
        }
        .tint(Color.secondaryPurple)
        .sheet(isPresented: $showingAddCourse) {
            AddNewCourseView()
        }
        .confirmationDialog("Options", isPresented: $showingOptions, presenting: selectedCourse) { course in
            optionsButtons(for: course)
        }
        .onAppear {
            print("LibraryView: onAppear - Subscribing to Firestore courses.")
            print("Fetched courses on appear: \(firestoreCourses)")
        }
    }

    @ViewBuilder
    private var courseListView: some View {
        List {
            ForEach(sortedGroupKeys, id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(groupedCourses[key] ?? []) { course in
                        NavigationLink(destination: CourseDetailView(course: course)) {
                            courseRow(for: course)
                        }
                        .swipeActions(edge: .leading) {
                            deleteButton(for: course)
                            optionsButton(for: course)
                        }
                        .swipeActions(edge: .trailing) {
                            deleteButton(for: course)
                            optionsButton(for: course)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(InsetGroupedListStyle())
    }

    private func deleteButton(for course: Course) -> some View {
        Button(role: .destructive) {
            print("Delete tapped for \(course.name)")
            deleteCourse(course: course)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func optionsButton(for course: Course) -> some View {
        Button {
            showingOptions = true
            selectedCourse = course
        } label: {
            Image(systemName: "ellipsis")
        }
        .tint(.gray)
    }

    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search courses", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "mic.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding()
    }

    private func courseRow(for course: Course) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(course.name)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(course.code)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }.padding(5)

            Spacer()
        }
    }

    private func optionsButtons(for course: Course) -> some View {
        Group {
            Button("View Details") {
                print("View Details from confirmation dialog for \(course.name)")
            }
            Button("Share") {
                print("Share tapped for \(course.name)")
            }
            Button("Save Offline") {
                print("Save Offline tapped for \(course.name)")
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var addToLibraryButton: some View {
        HStack {
            Spacer()
            Button(action: {
                showingAddCourse = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16))
                    .padding(8)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .shadow(radius: 4)
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }

    private func deleteCourse(course: Course) {
        guard let id = course.docID else {
            print("Error: Course has no ID.")
            return
        }

        db.collection("courses").document(id).delete { error in
            if let error = error {
                print("Error deleting course: \(error.localizedDescription)")
            } else {
                print("Course deleted successfully!")
            }
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(FirestoreManager())
}
