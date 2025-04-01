//
//  LibraryView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var searchText = ""
    @State private var showingOptions = false
    @State private var selectedCourse: Course?
    @State private var groupingOption: GroupingOption = .semester
    
    let courses = exampleCourses
    
    enum GroupingOption: String, CaseIterable, Identifiable {
        case alphabetical = "Alphabetical"
        case semester = "Semester"
        var id: String { self.rawValue }
    }
    
    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                
                if groupingOption == .alphabetical {
                    List {
                        ForEach(sortedGroupKeys, id: \.self) { key in
                            Section(header: Text(key)) {
                                ForEach(groupedCourses[key] ?? []) { course in
                                    NavigationLink(destination: CourseDetailView(course: course)) {
                                        courseRow(for: course)
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button(role: .destructive) {
                                            print("Delete tapped for \(course.name)")
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            showingOptions = true
                                            selectedCourse = course
                                        } label: {
                                            Image(systemName: "ellipsis")
                                        }
                                        .tint(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(InsetGroupedListStyle())
                } else {
                    List {
                        ForEach(sortedGroupKeys, id: \.self) { key in
                            Section(header: Text(key)) {
                                ForEach(groupedCourses[key] ?? []) { course in
                                    NavigationLink(destination: CourseDetailView(course: course)) {
                                        courseRow(for: course)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            print("Delete tapped for \(course.name)")
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            showingOptions = true
                                            selectedCourse = course
                                        } label: {
                                            Image(systemName: "ellipsis")
                                        }
                                        .tint(.gray)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Library")
        }
        .tint(Color.secondaryPurple)
        .confirmationDialog("Options", isPresented: $showingOptions, presenting: selectedCourse) { course in
            optionsButtons(for: course)
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
    
    private func courseRow(for course: Course) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(course.name)
                    .font(.headline)
                Text(course.documents.first?.url ?? "")
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
}

#Preview {
    LibraryView()
}
