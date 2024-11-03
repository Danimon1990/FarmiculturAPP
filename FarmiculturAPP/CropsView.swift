import SwiftUI
/*
struct CropsView: View {
    @Binding var crops: [Crop]
    let saveAction: () -> Void

    var body: some View {
        NavigationView {
            List($crops) { $crop in
                NavigationLink(
                    destination: CropDetailView(crop: $crop, saveAction: saveAction)
                ) {
                    Text(crop.name)
                }
            }
            .navigationTitle("Crops")
            .navigationBarItems(trailing:
            Button(action: {
                let newCrop = Crop() // Using default initializer
                crops.append(newCrop)
                saveAction()
            }) {
                Image(systemName: "plus")
            })
        }
    }



    
    @ViewBuilder
    private func destinationView(for crop: Binding<Crop>) -> some View {
        if crop.wrappedValue.type == .seeds {
            SeedsView(crop: crop)
        } else {
            GreenhouseView(crop: crop)
        }
    }
}
*/
struct CropsView: View {
    @Binding var crops: [Crop]
    let saveAction: () -> Void
    
    @State private var showingNewCropView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach($crops) { $crop in
                    NavigationLink(destination: destinationView(for: $crop)) {
                        Text(crop.name)
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
                totalSeeds: calculateTotalSeeds() // Reorder arguments
            )
        } else {
            CropDetailView(
                crop: crop,
                saveAction: saveAction,
                deleteAction: { deleteCrop(crop: crop.wrappedValue) }
            )
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

