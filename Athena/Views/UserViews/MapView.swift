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
            center: CLLocationCoordinate2D(latitude: 33.4484, longitude: -112.0740), // Phoenix coordinates
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            // Map content can be added here
        }
        .ignoresSafeArea()
        .searchable(text: $searchText, prompt: "Search for a place")
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty, newValue.count > 3 {
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
        // This would typically use MKLocalSearch to find locations
        // Basic implementation for now
        print("Searching for: \(searchText)")
    }
}

#Preview {
    MapView()
}
