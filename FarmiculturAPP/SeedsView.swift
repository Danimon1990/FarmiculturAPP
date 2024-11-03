//
//  SeedsView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 1/1/25.
//

import SwiftUI
struct SeedsView: View {
    @Binding var crop: Crop
    let deleteAction: () -> Void // Action to delete the crop
    var totalSeeds: Int
    @State private var isAddingUpdate = false
    @State private var newObservationText = ""
    @State private var newObservationDate = Date()
    @State private var showingDeleteConfirmation = false // State for confirmation dialog
    
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details for \(crop.name)")
                        .font(.largeTitle)
                        .padding(.bottom)

                    Text("Seed Variety: \(crop.seedVariety ?? "N/A")")
                    Text("Number of Seeds: \(crop.numberOfSeeds ?? 0)")
                    Text("Start Date: \(formattedDate($crop.seedStartDate.wrappedValue))")
                    Text("Location: \(crop.seedLocation ?? "N/A")")
                    Text("Pot Size: \(crop.potSize ?? "N/A")")
                    Text("Soil Used: \(crop.soilUsed ?? "N/A")")
                }
                .padding(.horizontal)

                Divider()

                // Observations
                Text("Observations")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(crop.observations) { observation in
                    VStack(alignment: .leading) {
                        Text("Date: \(formattedDate(observation.date))")
                            .font(.subheadline)
                        Text(observation.text)
                            .font(.body)
                            .padding(.bottom, 10)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            // Add Update Button
            Button(action: { isAddingUpdate = true }) {
                Text("Add Update")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Seed Batch")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive, action: {
                    showingDeleteConfirmation = true // Show confirmation dialog
                }) {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Crop", isPresented: $showingDeleteConfirmation) {
            Button("Yes", role: .destructive) {
                deleteAction() // Execute delete action
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this crop?")
        }
        .sheet(isPresented: $isAddingUpdate) {
            AddUpdateView(crop: $crop, isAddingUpdate: $isAddingUpdate)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
