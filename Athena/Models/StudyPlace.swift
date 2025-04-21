//
//  StudyPlace.swift
//  Athena
//
//  Created by Dhruv Bansal on 3/31/25.
//

import CoreLocation
import Foundation
import MapKit

struct StudyPlace: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String
    let coordinate: Coordinate

    struct Coordinate: Decodable {
        let latitude: Double
        let longitude: Double
    }

    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

struct StudyPlacesResponse: Decodable {
    let study_places: [StudyPlace]
}
