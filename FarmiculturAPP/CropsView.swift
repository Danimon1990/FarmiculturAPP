import SwiftUI

struct CropsView: View {
    @Binding var crops: [Crop]
    let saveAction: () -> Void
    
    @State private var showingNewCropView = false
    
    var body: some View {
        NavigationView {
            List {
                // Group crops by type and create sections
                ForEach(CropType.allCases, id: \.self) { cropType in
                    Section(header: Text(cropType.rawValue)) {
                        ForEach(crops.filter { $0.type == cropType }) { crop in
                            NavigationLink(destination: destinationView(for: Binding(get: {
                                crop
                            }, set: { newCrop in
                                if let index = crops.firstIndex(where: { $0.id == crop.id }) {
                                    crops[index] = newCrop
                                }
                            }))) {
                                Text(crop.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Crops")
            .navigationBarItems(
                trailing: Button(action: {
                    showingNewCropView = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingNewCropView) {
                NewCropView(crops: $crops)
                    .onDisappear(perform: saveAction)
            }
            .onAppear {
                crops = CropsDataManager.shared.loadCrops() // Reload crops on view appearance
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for crop: Binding<Crop>) -> some View {
        if crop.wrappedValue.type == .seeds {
            SeedsView(
                crop: crop,
                deleteAction: { deleteCrop(crop: crop.wrappedValue) },
                totalSeeds: calculateTotalSeeds(), // Reorder arguments
                saveAction: saveAction
            )
        } else {
            GreenhouseView(crop: crop, saveAction: saveAction)
        }
    }
    
    private func calculateTotalSeeds() -> Int {
        crops.filter { $0.type == .seeds }
             .reduce(0) { $0 + ($1.numberOfSeeds ?? 0) }
    }
    
    private func deleteCrop(crop: Crop) {
        if let index = crops.firstIndex(where: { $0.id == crop.id }) {
            crops.remove(at: index) // Remove the crop from the list
            saveAction() // Save the updated list
        }
    }
}
