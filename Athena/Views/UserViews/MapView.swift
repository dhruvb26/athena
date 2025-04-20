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
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            ForEach(viewModel.studyLocations) { location in
                Marker(location.name, coordinate: location.coordinate)
                    .tint(.red)
            }
        }
        .ignoresSafeArea()
        .searchable(text: $viewModel.searchText, prompt: "Search for a place")
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty, newValue.count > 2 {
                viewModel.searchPlaces()
            }
        }
        .navigationTitle("Find a Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    MapView()
}
