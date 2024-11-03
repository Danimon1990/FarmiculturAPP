//
//  HarvestView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//

import SwiftUI
struct HarvestView: View {
    var totalSeeds: Int

    var body: some View {
        VStack {
            Text("Total Seeds Planted")
                .font(.headline)
                .padding()

            Text("\(totalSeeds)")
                .font(.largeTitle)
                .foregroundColor(.green)
                .padding()

            // Add more Harvest tab content here
        }
        .navigationTitle("Harvest")
    }
}
