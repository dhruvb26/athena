//
//  StudyPlace.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/31/25.
//

import Foundation
import MapKit

import CoreLocation

struct StudyPlace: Identifiable, Decodable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let description: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct StudyPlacesResponse: Decodable {
    let study_places: [StudyPlace]
}
