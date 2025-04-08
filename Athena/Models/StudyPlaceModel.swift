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
        description:
        "Main campus library with multiple floors for different study environments. The 4th floor offers quiet studying with individual nooks."
    ),
    StudyPlace(
        name: "Noble Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4178, longitude: -111.9331),
        description:
        "Science and engineering library with 55 individual study rooms and a Silent Study area on the second floor."
    ),
    StudyPlace(
        name: "Memorial Union",
        coordinate: CLLocationCoordinate2D(latitude: 33.4169, longitude: -111.9350),
        description: "Student center with various study spaces and dining options."
    ),
    StudyPlace(
        name: "Computing Commons",
        coordinate: CLLocationCoordinate2D(latitude: 33.4192, longitude: -111.9303),
        description: "Computer labs, study areas, and rooftop patios with views of campus."
    ),
    StudyPlace(
        name: "Design Building",
        coordinate: CLLocationCoordinate2D(latitude: 33.4218, longitude: -111.9362),
        description: "Design school with modern study spaces."
    ),
    StudyPlace(
        name: "SDFC",
        coordinate: CLLocationCoordinate2D(latitude: 33.4214, longitude: -111.9232),
        description: "Sun Devil Fitness Complex with study areas."
    ),
    StudyPlace(
        name: "Barrett Honors College",
        coordinate: CLLocationCoordinate2D(latitude: 33.4153, longitude: -111.9314),
        description: "Quiet study spaces for students."
    ),
    StudyPlace(
        name: "Tempe Center",
        coordinate: CLLocationCoordinate2D(latitude: 33.4245, longitude: -111.9285),
        description: "Study areas and classrooms."
    ),
    // Additional study places from web search
    StudyPlace(
        name: "Music Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4187, longitude: -111.9365),
        description:
        "Near-silent study environment on the library's west side with study nooks and comfortable seating."
    ),
    StudyPlace(
        name: "Design and the Arts Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4210, longitude: -111.9370),
        description:
        "Located in the Design North Building, focusing on design subjects like architecture and urban planning."
    ),
    StudyPlace(
        name: "Student Pavilion",
        coordinate: CLLocationCoordinate2D(latitude: 33.4180, longitude: -111.9340),
        description:
        "Beautiful building with open layout on first floor for group work and quieter upper floors for focused study."
    ),
    StudyPlace(
        name: "Interdisciplinary Science and Technology Building 4",
        coordinate: CLLocationCoordinate2D(latitude: 33.4195, longitude: -111.9317),
        description: "Third floor offers quiet environment with ample seating and a secluded feel."
    ),
    StudyPlace(
        name: "Hayden Lawn",
        coordinate: CLLocationCoordinate2D(latitude: 33.4198, longitude: -111.9353),
        description:
        "Outdoor grassy area outside Hayden Library, popular for studying on pleasant days."
    ),
    StudyPlace(
        name: "Farmer Building Courtyard",
        coordinate: CLLocationCoordinate2D(latitude: 33.4222, longitude: -111.9331),
        description:
        "Open-air courtyard with calming fountains providing a tranquil outdoor study environment."
    ),
    StudyPlace(
        name: "Vista Del Sol Walkway",
        coordinate: CLLocationCoordinate2D(latitude: 33.4110, longitude: -111.9290),
        description:
        "Miniature palm walk on south campus with benches beneath palm trees, near food options."
    ),
    StudyPlace(
        name: "Student Services Building Courtyard",
        coordinate: CLLocationCoordinate2D(latitude: 33.4190, longitude: -111.9330),
        description: "Silent outdoor spot with tables and chairs along the sides of the building."
    ),
    StudyPlace(
        name: "Armstrong Hall",
        coordinate: CLLocationCoordinate2D(latitude: 33.4150, longitude: -111.9355),
        description:
        "Near the Law Library with a courtyard equipped with tables and benches, open to all students."
    ),
    StudyPlace(
        name: "Secret Garden",
        coordinate: CLLocationCoordinate2D(latitude: 33.4203, longitude: -111.9340),
        description:
        "Hidden spot with potted plants and trees, perfect for those who prefer sitting on the ground in a quiet setting."
    ),
    StudyPlace(
        name: "Farmer Education Building",
        coordinate: CLLocationCoordinate2D(latitude: 33.4208, longitude: -111.9328),
        description:
        "Features a courtyard with a soothing fountain and large plants, giving off a unique atmosphere."
    ),
    StudyPlace(
        name: "Ross-Blakley Law Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4148, longitude: -111.9357),
        description:
        "Law library with modern architecture, primarily for law students but with study areas nearby."
    ),
    StudyPlace(
        name: "Cartel Coffee",
        coordinate: CLLocationCoordinate2D(latitude: 33.4234, longitude: -111.9394),
        description: "Off-campus coffee shop popular among upperclassmen and graduate students."
    ),
    StudyPlace(
        name: "Tempe Public Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.3932, longitude: -111.9105),
        description:
        "Off-campus library offering absolute quiet, spacious environment with various seating options."
    ),
    StudyPlace(
        name: "Cafetal Coffee",
        coordinate: CLLocationCoordinate2D(latitude: 33.4226, longitude: -111.9405),
        description:
        "Off-campus coffee shop known for friendly atmosphere and quality coffee, within walking distance."
    ),
    StudyPlace(
        name: "Downtown Phoenix Campus Library",
        coordinate: CLLocationCoordinate2D(latitude: 33.4532, longitude: -112.0730),
        description:
        "Library at the Downtown Phoenix campus with study rooms and various academic resources."
    ),
]
