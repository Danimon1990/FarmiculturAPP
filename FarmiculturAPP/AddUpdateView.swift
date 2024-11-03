//
//  AddUpdateView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 1/1/25.
//
import SwiftUI
struct AddUpdateView: View {
    @Binding var crop: Crop
    @Binding var isAddingUpdate: Bool
    @State private var newObservationText: String = ""
    @State private var newObservationDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add Observation")) {
                    TextField("Observation", text: $newObservationText)
                    DatePicker("Date", selection: $newObservationDate, displayedComponents: .date)
                }
                Section {
                    HStack {
                        Button("Cancel") {
                            isAddingUpdate = false
                        }
                        .foregroundColor(.red)

                        Spacer()

                        Button("Confirm") {
                            confirmObservation()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("New Update")
        }
    }

    private func confirmObservation() {
        // Append the observation to the crop
        let newObservation = Observation(date: newObservationDate, text: newObservationText)
        crop.observations.append(newObservation)

        // Clear input
        newObservationText = ""
        newObservationDate = Date()

        // Dismiss the view
        isAddingUpdate = false
    }
}
