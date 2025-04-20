import Foundation
import MapKit
import SwiftUI

@MainActor
class MapViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.4244, longitude: -111.9283),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @Published var selectedPlace: StudyPlace?

    let studyLocations = asuStudyLocations

    func searchPlaces() {
        let searchTextLower = searchText.lowercased()
        let matchingLocations = studyLocations.filter {
            $0.name.lowercased().contains(searchTextLower)
                || $0.description.lowercased().contains(searchTextLower)
        }

        if let firstMatch = matchingLocations.first {
            selectedPlace = firstMatch

            let newRegion = MKCoordinateRegion(
                center: firstMatch.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )

            withAnimation {
                cameraPosition = .region(newRegion)
            }
        } else {
            print("No matching locations found for: \(searchText)")
        }
    }
}
