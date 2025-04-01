//
//  Course.swift
//  MainProject
//
//  Created by Dhruv Bansal on 3/29/25.
//

import Foundation

struct Course: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let author: String
}

let exampleCourses: [Course] = [
    Course(title: "SwiftUI Basics", description: "Learn how to build beautiful UIs using SwiftUI.", author: "Dhruv Bansal"),
    Course(title: "iOS Animations", description: "Add motion and delight to your apps.", author: "Emily Chen"),
    Course(title: "Firebase Integration", description: "Learn to authenticate users and sync data.", author: "Alex Rivera"),
    Course(title: "Advanced Swift", description: "Explore protocols, generics, and more.", author: "Jane Doe")
]
