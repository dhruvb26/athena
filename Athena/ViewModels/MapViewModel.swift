//
//  MapViewModel.swift
//  Athena
//
//  Created by Kanav Gupta on 3/28/25.
//

import Foundation
import Logging
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var studyLocations: [StudyPlace] = []
    @Published var searchText: String = ""
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var selectedPlace: StudyPlace?

    private let logger = Logger(label: "athena.MapViewModel")

    func fetchStudyLocations() {
        guard let url = URL(string: "https://athena-api-eight.vercel.app/study_places") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data {
                do {
                    let decoded = try JSONDecoder().decode(StudyPlacesResponse.self, from: data)
                    let locations = decoded.study_places
                    DispatchQueue.main.async {
                        self.studyLocations = locations
                        if let first = locations.first {
                            self.cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: first.mapCoordinate,
                                    span: MKCoordinateSpan(
                                        latitudeDelta: 0.05, longitudeDelta: 0.05
                                    )
                                ))
                        }
                    }
                } catch {
                    self.logger.error("Decoding error: \(error)\n")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        self.logger.error("Raw JSON: \(jsonString)")
                    }
                }
            } else if let error {
                self.logger.error("HTTP request failed: \(error)")
            }
        }.resume()
    }

    func searchPlaces() {
        let searchTextLower = searchText.lowercased()
        let matchingLocations = studyLocations.filter {
            $0.name.lowercased().contains(searchTextLower)
                || $0.description.lowercased().contains(searchTextLower)
        }

        if let firstMatch = matchingLocations.first {
            selectedPlace = firstMatch

            let newRegion = MKCoordinateRegion(
                center: firstMatch.mapCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            withAnimation {
                cameraPosition = .region(newRegion)
            }
        } else {
            logger.error("No matching locations found for: \(searchText)")
        }
    }
}
