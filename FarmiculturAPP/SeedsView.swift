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
    let saveAction: () -> Void
    @State private var isAddingUpdate = false
    @State private var newObservationText = ""
    @State private var newObservationDate = Date()
    @State private var showingDeleteConfirmation = false // State for confirmation dialog
    @State private var showAddTaskSheet = false
    
    
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

                // Tasks section
                Section(header: Text("Tasks").font(.headline).padding(.leading)) {
                    if crop.tasks.isEmpty {
                        Text("No tasks yet.")
                            .foregroundColor(.secondary)
                            .padding(.leading)
                    } else {
                        ForEach(crop.tasks) { task in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(.subheadline)
                                    if let due = task.dueDate {
                                        Text("Due: \(due, formatter: dateFormatter)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if task.isCompleted {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    Button(action: { showAddTaskSheet = true }) {
                        Label("Add Task", systemImage: "plus")
                            .padding(.leading)
                    }
                }

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
        .sheet(isPresented: $showAddTaskSheet) {
            AddTaskView(
                cropID: crop.id,
                creatorName: "Farmer", // Replace with actual user name if available
                onSave: { task in
                    crop.tasks.append(task)
                    saveAction() // Save the crop when a task is added
                }
            )
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()
