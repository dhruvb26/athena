//
//  CourseDetailView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/1/25.
//

import SwiftUI

struct CourseDetailView: View {
    let course: Course
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
            
            Text("\(course.semester)")
                .font(.subheadline)
                .foregroundStyle(.gray)
                
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let previewCourses = exampleCourses
    CourseDetailView(course: previewCourses.first!)
}
