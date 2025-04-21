import Foundation
import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var studyLocations: [StudyPlace] = []
    @Published var searchText: String = ""
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var selectedPlace: StudyPlace?
    
    func fetchStudyLocations() {
        guard let url = URL(string: "http://0.0.0.0:8000/study_places") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(StudyPlacesResponse.self, from: data)
                    let locations = decoded.study_places
                    DispatchQueue.main.async {
                        self.studyLocations = locations
                        if let first = locations.first {
                            self.cameraPosition = .region(MKCoordinateRegion(
                                center: first.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            ))
                        }
                    }
                } catch {
                    print("Decoding error: \(error)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON: \(jsonString)")
                    }
                }
            }
            else if let error = error {
                print("HTTP request failed: \(error)")
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
