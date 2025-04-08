//
//  StudyPlaceModel.swift
//  Athena
//
//  Created on 4/7/25.
//

import Foundation
import MapKit

struct StudyPlace: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
}

let asuStudyLocations = [
    StudyPlace(
        name: "Hayden Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4195, longitude: -111.9348),
        description: "Main campus library"
    ),
    StudyPlace(
        name: "Noble Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4178, longitude: -111.9331),
        description: "Science and engineering library"
    ),
    StudyPlace(
        name: "Memorial Union",
        coordinate: CLLocationCoordinate2D(latitude: 33.4169, longitude: -111.9350),
        description: "Student center with study spaces"
    ),
    StudyPlace(
        name: "Computing Commons",
        coordinate: CLLocationCoordinate2D(latitude: 33.4192, longitude: -111.9303),
        description: "Computer labs and study areas"
    ),
    StudyPlace(
        name: "Design Building",
        coordinate: CLLocationCoordinate2D(latitude: 33.4218, longitude: -111.9362),
        description: "Design school with study spaces"
    ),
    StudyPlace(
        name: "SDFC",
        coordinate: CLLocationCoordinate2D(latitude: 33.4214, longitude: -111.9232),
        description: "Sun Devil Fitness Complex with study areas"
    ),
    StudyPlace(
        name: "Barrett Honors College",
        coordinate: CLLocationCoordinate2D(latitude: 33.4153, longitude: -111.9314),
        description: "Quiet study spaces for students"
    ),
    StudyPlace(
        name: "Tempe Center",
        coordinate: CLLocationCoordinate2D(latitude: 33.4245, longitude: -111.9285),
        description: "Study areas and classrooms"
    ),
]
