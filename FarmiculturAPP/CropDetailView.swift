import SwiftUI

struct CropDetailView: View {
    @Binding var crop: Crop
    
    let saveAction: () -> Void
    let deleteAction: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack {
            // Title
            Text("Crop: \(crop.name)")
                .font(.largeTitle)
                .padding()
            
            // Active/Inactive Indicator
            Text("Currently \(crop.isActive ? "Active" : "Inactive")")
                .font(.headline)
                .foregroundColor(crop.isActive ? .green : .gray)
                .padding(.bottom, 10)
            
            ScrollView {
                
                // Only show layout if this is a greenhouse (or similar)
                if crop.type == .greenhouse || crop.type == .highTunnels || crop.type == .outdoorBeds {
                    
                    // Make sure crop.sections ( [[Bed]] ) is not empty
                    if !crop.sections.isEmpty {
                        // For each "section" (one row in the greenhouse)
                        ForEach(crop.sections.indices, id: \.self) { sectionIndex in
                            HStack(spacing: 8) {
                                // For each bed in that section
                                ForEach(crop.sections[sectionIndex].indices, id: \.self) { bedIndex in
                                    let bed = crop.sections[sectionIndex][bedIndex]
                                    
                                    // Navigation to BedEditView
                                    NavigationLink(destination: BedEditView(
                                        sectionIndex: sectionIndex,
                                        bedIndex: bedIndex,
                                        crop: $crop
                                    )) {
                                        // Show only the number of plants (plantCount)
                                        Text("\(bed.plantCount)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 40, minHeight: 40)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No sections/beds to display.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    
                    Divider()
                        .padding(.top, 8)
                    
                    // Additional info, e.g. total plants, variety summary
                    Text("Total Plants: \(calculateTotalPlants())")
                        .font(.headline)
                        .padding(.top, 4)
                    
                } else {
                    // Non-greenhouse crops
                    Text("No greenhouse layout for this crop type.")
                        .italic()
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Crop Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Crop", isPresented: $showingDeleteConfirmation) {
            Button("Yes", role: .destructive) {
                deleteAction()
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this crop?")
        }
        .onDisappear(perform: saveAction)
    }
    
    /// Example helper to sum up all plant counts
    private func calculateTotalPlants() -> Int {
        crop.sections
            .flatMap { $0 }
            .map { $0.plantCount }
            .reduce(0, +)
    }
}
