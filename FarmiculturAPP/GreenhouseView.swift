//
//  GreenhouseView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import SwiftUI

struct GreenhouseView: View {
    @Binding var crop: Crop

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details for \(crop.name)")
                .font(.largeTitle)
                .padding()

            ScrollView {
                LazyVStack(spacing: 20) { // Stack sections vertically
                    ForEach(crop.sections.indices, id: \.self) { sectionIndex in
                        VStack(alignment: .leading, spacing: 10) {
                            // Section Label
                            Text("Section \(sectionIndex + 1)")
                                .font(.headline)
                                .padding(.leading)

                            // Beds in the Section
                            HStack(spacing: 10) {
                                ForEach(crop.sections[sectionIndex]) { bed in
                                    VStack {
                                        Text("Plants: \(bed.plantCount)")
                                            .font(.caption)
                                        Text(bed.state)
                                            .font(.caption2)
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(Rectangle().stroke(Color.gray, lineWidth: 1))
                                    .onTapGesture {
                                        navigateToBedEdit(bed: bed)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(crop.name) Layout")
    }

    private func navigateToBedEdit(bed: Bed) {
        // Implement navigation to BedEditView
        print("Navigate to BedEditView for Bed \(bed.bed) in Section \(bed.section)")
    }
}
