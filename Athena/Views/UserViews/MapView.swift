//
//  MapView.swift
//  Athena
//
//  Created by Dhruv Bansal on 4/7/25.
//

import MapKit
import SwiftUI

struct MapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 33.4244, longitude: -111.9283),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )
    @State private var selectedPlace: StudyPlace?
    let studyLocations = asuStudyLocations

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(studyLocations) { location in
                Marker(location.name, coordinate: location.coordinate)
                    .tint(.red)
            }
        }
        .ignoresSafeArea()
        .searchable(text: $searchText, prompt: "Search for a place")
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty, newValue.count > 2 {
                searchPlaces()
            }
        }
        .navigationTitle("Find a Place")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                #else
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                #endif
            }
    }

    private func searchPlaces() {
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

#Preview {
    MapView()
}
