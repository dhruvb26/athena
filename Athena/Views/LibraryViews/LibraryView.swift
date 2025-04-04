//
//  LibraryView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    searchBarView

                    HStack {
                        Picker("Group by", selection: $viewModel.groupingOption) {
                            ForEach(LibraryViewModel.GroupingOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .accentColor(.primary)
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
        .sheet(isPresented: $viewModel.showingAddCourse) {
            AddCourseView()
        }
        .confirmationDialog("Options", isPresented: $viewModel.showingOptions, presenting: viewModel.selectedCourse) { course in
            optionsButtons(for: course)
        }
        .onAppear {
            Task {
                await viewModel.fetchCourses()
            }
        }
    }

    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search courses", text: $viewModel.searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
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
            ForEach(viewModel.sortedGroupKeys, id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(viewModel.groupedCourses[key] ?? []) { course in
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
            viewModel.deleteCourse(course)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private func optionsButton(for course: Course) -> some View {
        Button {
            viewModel.selectedCourse = course
            viewModel.showingOptions = true
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

    private var addToLibraryButton: some View {
        HStack {
            Spacer()
            Button {
                viewModel.showingAddCourse = true
            } label: {
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
}

#Preview {
    LibraryView()
}
