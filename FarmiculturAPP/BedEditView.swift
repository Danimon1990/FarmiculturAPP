import SwiftUI

struct BedEditView: View {
    let sectionIndex: Int
    let bedIndex: Int
    @Binding var crop: Crop
    let saveAction: () -> Void
    
    @State private var newVarietyName: String = ""
    @State private var newVarietyCount: String = ""
    @State private var showingAddVariety = false
    @State private var showingHarvest = false
    
    var body: some View {
        Form {
            Section(header: Text("Bed Info")) {
                Text("Section \(sectionIndex + 1), Bed \(bedIndex + 1)")
                
                Text("Total Plants: \(crop.sections[sectionIndex][bedIndex].totalPlants)")
                    .font(.headline)
                
                Picker("Bed State", selection: $crop.sections[sectionIndex][bedIndex].state) {
                    ForEach(BedState.allCases, id: \.self) { state in
                        Text(state.displayName)
                            .tag(state)
                    }
                }
                .onChange(of: crop.sections[sectionIndex][bedIndex].state) { _ in
                    saveAction()
                }
                
                Text(crop.sections[sectionIndex][bedIndex].state.displayName)
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                if crop.sections[sectionIndex][bedIndex].state == .growing || 
                   crop.sections[sectionIndex][bedIndex].state == .harvesting {
                    Button("Harvest Plants") {
                        showingHarvest = true
                    }
                }
            }
            
            Section(header: Text("Plant Varieties")) {
                ForEach(crop.sections[sectionIndex][bedIndex].varieties) { variety in
                    HStack {
                        Text(variety.name)
                        Spacer()
                        Text("\(variety.count) plants")
                    }
                }
                .onDelete { indexSet in
                    crop.sections[sectionIndex][bedIndex].varieties.remove(atOffsets: indexSet)
                    saveAction()
                }
                
                Button("Add Variety") {
                    showingAddVariety = true
                }
            }
        }
        .navigationTitle("Edit Bed")
        .sheet(isPresented: $showingAddVariety) {
            NavigationView {
                Form {
                    Section(header: Text("New Variety")) {
                        TextField("Variety Name", text: $newVarietyName)
                        TextField("Number of Plants", text: $newVarietyCount)
                            .keyboardType(.numberPad)
                    }
                    
                    Section {
                        Button("Add") {
                            if let count = Int(newVarietyCount), !newVarietyName.isEmpty {
                                let newVariety = PlantVariety(id: UUID(), name: newVarietyName, count: count)
                                crop.sections[sectionIndex][bedIndex].varieties.append(newVariety)
                                
                                // Auto-change bed state to growing if it was ready
                                if crop.sections[sectionIndex][bedIndex].state == .ready {
                                    crop.sections[sectionIndex][bedIndex].state = .growing
                                }
                                
                                newVarietyName = ""
                                newVarietyCount = ""
                                showingAddVariety = false
                                saveAction() // Save when a new variety is added
                            }
                        }
                        .disabled(newVarietyName.isEmpty || Int(newVarietyCount) == nil)
                    }
                }
                .navigationTitle("Add Variety")
                .navigationBarItems(trailing: Button("Cancel") {
                    showingAddVariety = false
                })
            }
        }
        .sheet(isPresented: $showingHarvest) {
            HarvestView(
                sectionIndex: sectionIndex,
                bedIndex: bedIndex,
                crop: $crop,
                saveAction: saveAction
            )
        }
    }
}
