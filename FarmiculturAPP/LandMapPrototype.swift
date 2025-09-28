import SwiftUI

struct LandMapPrototype: View {
    @State private var rows: Int = 6
    @State private var columns: Int = 8
    @State private var selected: GridPosition? = nil
    @State private var mapAssignments: [GridPosition: String] = [:] // GridPosition -> Crop.id
    @State private var showCropPicker = false
    @State private var saveMessage: String? = nil
    
    // Pass the crops list from the app
    var crops: [Crop]
    
    // For legend
    let typeColors: [CropType: Color] = [
        .greenhouse: .green,
        .outdoorBeds: .brown,
        .seeds: .yellow,
        .treeCrops: .orange,
        .highTunnels: .blue
    ]
    
    var body: some View {
        VStack {
            Text("Land Map Prototype")
                .font(.title)
                .padding(.bottom)
            
            // Controls for grid size
            HStack {
                Stepper("Rows: \(rows)", value: $rows, in: 1...12)
                Stepper("Columns: \(columns)", value: $columns, in: 1...16)
            }
            .padding(.bottom)
            
            // The grid
            GeometryReader { geometry in
                let boxSize = min(geometry.size.width / CGFloat(columns), geometry.size.height / CGFloat(rows))
                VStack(spacing: 4) {
                    ForEach(0..<rows, id: \..self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \..self) { col in
                                let pos = GridPosition(row: row, col: col)
                                let crop = mapAssignments[pos].flatMap { id in crops.first { $0.id == id } }
                                LandMapBoxView(
                                    pos: pos,
                                    crop: crop,
                                    isSelected: selected == pos,
                                    boxSize: boxSize,
                                    onTap: {
                                        selected = pos
                                        showCropPicker = true
                                    },
                                    boxColor: boxColor,
                                    cropAbbreviation: cropAbbreviation
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1.3, contentMode: .fit)
            .padding()
            
            // Save/Load
            HStack {
                Button("Save Map") {
                    saveMap()
                }
                .buttonStyle(.borderedProminent)
                .padding(.trailing)
                Button("Load Map") {
                    loadMap()
                }
            }
            if let saveMessage = saveMessage {
                Text(saveMessage)
                    .font(.footnote)
                    .foregroundColor(.green)
            }
            
            // Legend
            legendView
                .padding(.top)
            
            Text("Tap a box to assign a crop. Adjust grid size above. Assigned crops update color and label. Unassigned = gray. Inactive = black.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showCropPicker) {
            CropPickerView(
                crops: crops,
                onSelect: { crop in
                    if let pos = selected {
                        if let crop = crop {
                            mapAssignments[pos] = crop.id
                        } else {
                            mapAssignments[pos] = nil
                        }
                    }
                    showCropPicker = false
                },
                onClear: {
                    if let pos = selected {
                        mapAssignments[pos] = nil
                    }
                    showCropPicker = false
                }
            )
        }
        .onAppear {
            loadMap()
        }
        .onChange(of: crops) { _ in
            // Remove assignments for deleted crops
            let cropIDs = Set(crops.map { $0.id })
            mapAssignments = mapAssignments.filter { $0.value == nil || cropIDs.contains($0.value) }
        }
    }
    
    // MARK: - Helpers
    func boxColor(for crop: Crop?) -> Color {
        guard let crop = crop else { return Color.gray.opacity(0.2) }
        if !crop.isActive { return .black }
        return typeColors[crop.type] ?? .gray
    }
    
    func cropAbbreviation(_ crop: Crop) -> String {
        let words = crop.name.split(separator: " ")
        if words.count == 1 { return String(words[0].prefix(3)).uppercased() }
        return words.map { String($0.prefix(1)).uppercased() }.joined()
    }
    
    func saveMap() {
        let dict = mapAssignments.mapValues { $0 ?? "" }
        UserDefaults.standard.setValue(["rows": rows, "columns": columns, "assignments": dict], forKey: "landMapPrototype")
        saveMessage = "Map saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saveMessage = nil }
    }
    
    func loadMap() {
        guard let dict = UserDefaults.standard.dictionary(forKey: "landMapPrototype") as? [String: Any],
              let savedRows = dict["rows"] as? Int,
              let savedColumns = dict["columns"] as? Int,
              let assignments = dict["assignments"] as? [String: String] else { return }
        rows = savedRows
        columns = savedColumns
        mapAssignments = assignments.reduce(into: [:]) { result, pair in
            if let pos = GridPosition.fromString(pair.key) {
                result[pos] = pair.value.isEmpty ? nil : pair.value
            }
        }
    }
    
    var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legend:").bold()
            HStack(spacing: 12) {
                ForEach(CropType.allCases, id: \.self) { type in
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(typeColors[type] ?? .gray)
                            .frame(width: 18, height: 18)
                            .cornerRadius(3)
                        Text(type.rawValue.capitalized)
                            .font(.caption)
                    }
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.black).frame(width: 18, height: 18).cornerRadius(3)
                    Text("Inactive").font(.caption)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 18, height: 18).cornerRadius(3)
                    Text("Unassigned").font(.caption)
                }
            }
        }
    }
}

struct LandMapBoxView: View {
    let pos: GridPosition
    let crop: Crop?
    let isSelected: Bool
    let boxSize: CGFloat
    let onTap: () -> Void
    let boxColor: (Crop?) -> Color
    let cropAbbreviation: (Crop) -> String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(boxColor(crop))
                .frame(width: boxSize, height: boxSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                )
                .onTapGesture { onTap() }
            if let crop = crop {
                Text(cropAbbreviation(crop))
                    .font(.caption2)
                    .foregroundColor(.white)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(2)
            } else {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct GridPosition: Hashable {
    let row: Int
    let col: Int
    
    // For saving/loading
    var stringValue: String { "\(row),\(col)" }
    static func fromString(_ str: String) -> GridPosition? {
        let parts = str.split(separator: ",").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return GridPosition(row: parts[0], col: parts[1])
    }
}

struct CropPickerView: View {
    let crops: [Crop]
    var onSelect: (Crop?) -> Void
    var onClear: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Assign Crop")) {
                    ForEach(crops) { crop in
                        Button(action: { onSelect(crop) }) {
                            HStack {
                                Text(crop.name)
                                Spacer()
                                if !crop.isActive {
                                    Text("Inactive").foregroundColor(.gray).italic()
                                }
                                Rectangle()
                                    .fill(colorForType(crop))
                                    .frame(width: 18, height: 18)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    Button("Clear Assignment", role: .destructive, action: { onClear() })
                }
            }
            .navigationTitle("Select Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onSelect(nil) } } }
        }
    }
    func colorForType(_ crop: Crop) -> Color {
        if !crop.isActive { return .black }
        switch crop.type {
        case .greenhouse: return .green
        case .outdoorBeds: return .brown
        case .seeds: return .yellow
        case .treeCrops: return .orange
        case .highTunnels: return .blue
        }
    }
}

struct LandMapPrototype_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock crops for preview
        let crops = [
            Crop(id: "1", type: .greenhouse, name: "Lettuce", isActive: true, sections: [], beds: [], sectionLength: 0, sectionWidth: 0, activities: [], expectedHarvestDate: Date(), seedVariety: nil, numberOfSeeds: nil, treeVariety: nil, numberOfTrees: nil, observations: [], seedStartDate: nil, seedLocation: nil, seedsPlanted: 0, potSize: nil, soilUsed: nil, tasks: []),
            Crop(id: "2", type: .outdoorBeds, name: "Carrots", isActive: true, sections: [], beds: [], sectionLength: 0, sectionWidth: 0, activities: [], expectedHarvestDate: Date(), seedVariety: nil, numberOfSeeds: nil, treeVariety: nil, numberOfTrees: nil, observations: [], seedStartDate: nil, seedLocation: nil, seedsPlanted: 0, potSize: nil, soilUsed: nil, tasks: []),
            Crop(id: "3", type: .seeds, name: "Tomato Seeds", isActive: false, sections: [], beds: [], sectionLength: 0, sectionWidth: 0, activities: [], expectedHarvestDate: Date(), seedVariety: nil, numberOfSeeds: nil, treeVariety: nil, numberOfTrees: nil, observations: [], seedStartDate: nil, seedLocation: nil, seedsPlanted: 0, potSize: nil, soilUsed: nil, tasks: [])
        ]
        LandMapPrototype(crops: crops)
    }
} 
