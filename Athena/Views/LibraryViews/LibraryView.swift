//
//  LibraryView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject var courseManager: CourseManager

    @State private var searchText = ""
    @State private var groupingOption: GroupingOption = .semester
    @State private var showingMapView = false
    @State private var showingAddCourse = false
    @State private var showingOptions = false
    @State private var selectedCourse: Course?

    enum GroupingOption: String, CaseIterable, Identifiable {
        case alphabetical = "Alphabetical"
        case semester = "Semester"
        var id: String { rawValue }
    }

    var filteredCourses: [Course] {
        if searchText.isEmpty {
            courseManager.userCourses
        } else {
            courseManager.userCourses.filter {
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
        return groupingOption == .alphabetical
            ? keys
            : keys.sorted {
                let num1 = Int($0.components(separatedBy: " ").last ?? "0") ?? 0
                let num2 = Int($1.components(separatedBy: " ").last ?? "0") ?? 0
                return num1 < num2
            }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                searchBarView

                HStack {
                    Picker("Group by", selection: $groupingOption) {
                        ForEach(GroupingOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .accentColor(.primary)
                    Spacer()

                    Button {
                        showingAddCourse = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                    }
                    .foregroundStyle(Color.secondaryPurple)
                    .buttonStyle(.plain)
                    .padding(10)
                }
                .padding(.horizontal)

                courseListView
            }

            Button {
                showingMapView = true
            } label: {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 35))
            }
            .foregroundStyle(Color.secondaryPurple)
            .padding(.trailing, 45)
            .padding(.bottom, 20)
        }
        .tint(Color.secondaryPurple)
        .sheet(isPresented: $showingAddCourse) {
            AddCourseView()
        }
        .confirmationDialog(
            "Options", isPresented: $showingOptions, presenting: selectedCourse
        ) { course in
            optionsButtons(for: course)
        }
        .onAppear {
            Task {
                await courseManager.loadCoursesFromDB()
            }
        }
        .navigationTitle("Library")
        .fullScreenCover(isPresented: $showingMapView) {
            NavigationView {
                MapView()
            }
        }
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
            }
            .padding(5)

            Spacer()
        }
    }

    private func deleteButton(for course: Course) -> some View {
        Button(role: .destructive) {
            courseManager.deleteCourseFromDB(course)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func optionsButton(for course: Course) -> some View {
        Button {
            selectedCourse = course
            showingOptions = true
        } label: {
            Image(systemName: "ellipsis")
        }
        .tint(.gray)
    }

    private func optionsButtons(for course: Course) -> some View {
        Group {
            Button("View Details") {
                print("View Details for \(course.name)")
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
}

#Preview {
    LibraryView()
        .environmentObject(CourseManager())
}
