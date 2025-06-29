import SwiftUI

struct HarvestSummaryView: View {
    @Binding var crops: [Crop]
    let saveAction: () -> Void
    
    // Calculate total plants growing across all crops
    var totalPlantsGrowing: Int {
        crops.reduce(0) { total, crop in
            total + crop.sections.reduce(0) { sectionTotal, section in
                sectionTotal + section.reduce(0) { bedTotal, bed in
                    bedTotal + bed.totalPlants
                }
            }
        }
    }
    
    // Get all plant varieties with their counts
    var plantVarieties: [PlantVarietySummary] {
        var varietyCounts: [String: Int] = [:]
        
        for crop in crops {
            for section in crop.sections {
                for bed in section {
                    for variety in bed.varieties {
                        varietyCounts[variety.name, default: 0] += variety.count
                    }
                }
            }
        }
        
        return varietyCounts.map { PlantVarietySummary(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    // Get all beds with plants that can be harvested
    var harvestableBeds: [HarvestableBed] {
        var beds: [HarvestableBed] = []
        
        for crop in crops {
            for (sectionIndex, section) in crop.sections.enumerated() {
                for (bedIndex, bed) in section.enumerated() {
                    if bed.totalPlants > 0 && (bed.state == .growing || bed.state == .harvesting) {
                        beds.append(HarvestableBed(
                            cropName: crop.name,
                            sectionIndex: sectionIndex,
                            bedIndex: bedIndex,
                            bed: bed,
                            crop: crop
                        ))
                    }
                }
            }
        }
        
        return beds.sorted { $0.cropName < $1.cropName }
    }
    
    // Get plants grouped by crop type
    var plantsByCropType: [CropTypeSummary] {
        var typeCounts: [CropType: Int] = [:]
        
        for crop in crops {
            let cropPlantCount = crop.sections.reduce(0) { sectionTotal, section in
                sectionTotal + section.reduce(0) { bedTotal, bed in
                    bedTotal + bed.totalPlants
                }
            }
            typeCounts[crop.type, default: 0] += cropPlantCount
        }
        
        return typeCounts.map { CropTypeSummary(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    // Get individual crops with their plant counts
    var cropsWithPlantCounts: [CropSummary] {
        crops.compactMap { crop in
            let plantCount = crop.sections.reduce(0) { sectionTotal, section in
                sectionTotal + section.reduce(0) { bedTotal, bed in
                    bedTotal + bed.totalPlants
                }
            }
            
            if plantCount > 0 {
                return CropSummary(
                    name: crop.name,
                    type: crop.type,
                    plantCount: plantCount,
                    crop: crop
                )
            }
            return nil
        }.sorted { $0.plantCount > $1.plantCount }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Summary Section
                Section(header: Text("Summary")) {
                    HStack {
                        Label("Total Plants Growing", systemImage: "leaf.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(totalPlantsGrowing)")
                            .foregroundColor(.green)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Label("Active Beds", systemImage: "square.grid.2x2.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(harvestableBeds.count)")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Label("Plant Varieties", systemImage: "tag.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(plantVarieties.count)")
                            .foregroundColor(.orange)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                
                // Plants by Crop Type Section
                if !plantsByCropType.isEmpty {
                    Section(header: Text("Plants by Crop Type")) {
                        ForEach(plantsByCropType) { cropType in
                            HStack {
                                Text(cropType.type.rawValue.capitalized)
                                    .font(.headline)
                                Spacer()
                                Text("\(cropType.count) plants")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // Individual Crops Section
                if !cropsWithPlantCounts.isEmpty {
                    Section(header: Text("Crops with Plants")) {
                        ForEach(cropsWithPlantCounts) { cropSummary in
                            NavigationLink(destination: destinationView(for: cropSummary.crop)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(cropSummary.name)
                                            .font(.headline)
                                        Text(cropSummary.type.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(cropSummary.plantCount) plants")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                
                // Plant Varieties Section
                if !plantVarieties.isEmpty {
                    Section(header: Text("Plant Varieties")) {
                        ForEach(plantVarieties) { variety in
                            HStack {
                                Label(variety.name, systemImage: "leaf")
                                    .font(.headline)
                                Spacer()
                                Text("\(variety.count)")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Text("plants")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Harvestable Beds Section
                if !harvestableBeds.isEmpty {
                    Section(header: Text("Beds Ready for Harvest")) {
                        ForEach(harvestableBeds) { harvestableBed in
                            NavigationLink(destination: HarvestView(
                                sectionIndex: harvestableBed.sectionIndex,
                                bedIndex: harvestableBed.bedIndex,
                                crop: Binding(
                                    get: { harvestableBed.crop },
                                    set: { newCrop in
                                        if let cropIndex = crops.firstIndex(where: { $0.id == newCrop.id }) {
                                            crops[cropIndex] = newCrop
                                        }
                                    }
                                ),
                                saveAction: saveAction
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(harvestableBed.cropName)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(harvestableBed.bed.totalPlants) plants")
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Section \(harvestableBed.sectionIndex + 1), Bed \(harvestableBed.bedIndex + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if !harvestableBed.bed.varieties.isEmpty {
                                        Text(harvestableBed.bed.varieties.map { "\($0.name) (\($0.count))" }.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text(harvestableBed.bed.state.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(bedStateColor(harvestableBed.bed.state))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section(header: Text("Beds Ready for Harvest")) {
                        Text("No beds with plants ready for harvest")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("Harvest")
        }
    }
    
    @ViewBuilder
    private func destinationView(for crop: Crop) -> some View {
        if crop.type == .seeds {
            SeedsView(
                crop: Binding(
                    get: { crop },
                    set: { newCrop in
                        if let cropIndex = crops.firstIndex(where: { $0.id == newCrop.id }) {
                            crops[cropIndex] = newCrop
                        }
                    }
                ),
                deleteAction: {
                    if let cropIndex = crops.firstIndex(where: { $0.id == crop.id }) {
                        crops.remove(at: cropIndex)
                        saveAction()
                    }
                },
                totalSeeds: crops.filter { $0.type == .seeds }.reduce(0) { $0 + ($1.numberOfSeeds ?? 0) },
                saveAction: saveAction
            )
        } else {
            GreenhouseView(
                crop: Binding(
                    get: { crop },
                    set: { newCrop in
                        if let cropIndex = crops.firstIndex(where: { $0.id == newCrop.id }) {
                            crops[cropIndex] = newCrop
                        }
                    }
                ),
                saveAction: saveAction
            )
        }
    }
    
    private func bedStateColor(_ state: BedState) -> Color {
        switch state {
        case .dirty: return .brown
        case .clean: return .gray
        case .ready: return .blue
        case .growing: return .green
        case .harvesting: return .orange
        }
    }
}

// Helper structs for data organization
struct PlantVarietySummary: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct CropTypeSummary: Identifiable {
    let id = UUID()
    let type: CropType
    let count: Int
}

struct CropSummary: Identifiable {
    let id = UUID()
    let name: String
    let type: CropType
    let plantCount: Int
    let crop: Crop
}

struct HarvestableBed: Identifiable {
    let id = UUID()
    let cropName: String
    let sectionIndex: Int
    let bedIndex: Int
    let bed: Bed
    let crop: Crop
}
