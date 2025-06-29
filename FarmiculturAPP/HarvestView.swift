//
//  HarvestView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//

import SwiftUI

struct HarvestView: View {
    let sectionIndex: Int
    let bedIndex: Int
    @Binding var crop: Crop
    let saveAction: () -> Void
    
    @State private var harvestAmount: String = ""
    @State private var showingConfirmation = false
    @State private var harvestedAmount = 0
    
    var body: some View {
        Form {
            Section(header: Text("Harvest Details")) {
                Text("Section \(sectionIndex + 1), Bed \(bedIndex + 1)")
                
                Text("Total Plants Available: \(crop.sections[sectionIndex][bedIndex].totalPlants)")
                    .font(.headline)
                
                TextField("Number of plants to harvest", text: $harvestAmount)
                    .keyboardType(.numberPad)
                
                if let amount = Int(harvestAmount), amount > 0 {
                    Text("This will harvest \(amount) plants")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button("Harvest") {
                    if let amount = Int(harvestAmount), amount > 0 {
                        harvestedAmount = amount
                        showingConfirmation = true
                    }
                }
                .disabled(Int(harvestAmount) == nil || Int(harvestAmount)! <= 0)
            }
        }
        .navigationTitle("Harvest Plants")
        .alert("Confirm Harvest", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                if let amount = Int(harvestAmount) {
                    let harvested = crop.sections[sectionIndex][bedIndex].harvest(amount: amount)
                    if harvested > 0 {
                        harvestAmount = ""
                        saveAction()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to harvest \(harvestedAmount) plants?")
        }
    }
}
