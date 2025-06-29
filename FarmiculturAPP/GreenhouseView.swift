//
//  GreenhouseView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import SwiftUI

struct BedView: View {
    let bed: Bed
    let sectionIndex: Int
    let bedIndex: Int
    @Binding var crop: Crop
    let saveAction: () -> Void
    
    var body: some View {
        NavigationLink(destination: BedEditView(
            sectionIndex: sectionIndex,
            bedIndex: bedIndex,
            crop: $crop,
            saveAction: saveAction
        )) {
            VStack(spacing: 4) {
                Text("\(bed.totalPlants)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(height: 25)
                
                if !bed.varieties.isEmpty {
                    Text("\(bed.varieties.count) var.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("Empty")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Text(bed.state.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 75, height: 75)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(bed.totalPlants > 0 ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            )
        }
    }
}

struct SectionView: View {
    let sectionIndex: Int
    let section: [Bed]
    @Binding var crop: Crop
    let saveAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Section \(sectionIndex + 1)")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(section.indices, id: \.self) { bedIndex in
                        BedView(
                            bed: section[bedIndex],
                            sectionIndex: sectionIndex,
                            bedIndex: bedIndex,
                            crop: $crop,
                            saveAction: saveAction
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct GreenhouseView: View {
    @Binding var crop: Crop
    @State private var showAddTaskSheet = false
    @State private var newTask: CropTask? = nil
    let saveAction: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(crop.sections.indices, id: \.self) { sectionIndex in
                        SectionView(
                            sectionIndex: sectionIndex,
                            section: crop.sections[sectionIndex],
                            crop: $crop,
                            saveAction: saveAction
                        )
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("\(crop.name) Layout")
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
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()
