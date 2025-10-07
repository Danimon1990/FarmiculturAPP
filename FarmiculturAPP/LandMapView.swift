//
//  LandMapView.swift
//  FarmiculturAPP
//
//  Updated Land Map for new Bed-based system
//

import SwiftUI

struct LandMapView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var rows: Int = 6
    @State private var columns: Int = 8
    @State private var selected: GridPosition? = nil
    @State private var mapAssignments: [GridPosition: String] = [:] // GridPosition -> CropArea.id
    @State private var showAreaPicker = false
    @State private var saveMessage: String? = nil
    @State private var cropAreas: [CropArea] = []
    @State private var isLoading = false
    
    // Colors for different area types
    let areaTypeColors: [CropAreaType: Color] = [
        .greenhouse: .green,
        .highTunnel: .blue,
        .outdoorBeds: .brown,
        .seedHouse: .orange,
        .treeCrops: .purple
    ]
    
    var body: some View {
        VStack {
            Text("Land Map")
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
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \.self) { col in
                                let pos = GridPosition(row: row, col: col)
                                let area = mapAssignments[pos].flatMap { id in cropAreas.first { $0.id == id } }
                                LandMapBoxView(
                                    pos: pos,
                                    area: area,
                                    isSelected: selected == pos,
                                    boxSize: boxSize,
                                    onTap: {
                                        selected = pos
                                        showAreaPicker = true
                                    },
                                    boxColor: boxColor,
                                    areaAbbreviation: areaAbbreviation
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
            
            Text("Tap a box to assign a crop area. Adjust grid size above. Each area shows its type color and abbreviated name. Unassigned squares appear gray.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showAreaPicker) {
            AreaPickerView(
                areas: cropAreas,
                onSelect: { area in
                    if let pos = selected {
                        if let area = area {
                            mapAssignments[pos] = area.id
                        } else {
                            mapAssignments[pos] = nil
                        }
                    }
                    showAreaPicker = false
                },
                onClear: {
                    if let pos = selected {
                        mapAssignments[pos] = nil
                    }
                    showAreaPicker = false
                }
            )
        }
        .onAppear {
            loadMap()
            loadAreas()
        }
        .onChange(of: cropAreas) { _ in
            // Remove assignments for deleted areas
            let areaIDs = Set(cropAreas.map { $0.id })
            mapAssignments = mapAssignments.filter { $0.value == nil || areaIDs.contains($0.value) }
        }
    }
    
    // MARK: - Helpers
    func boxColor(for area: CropArea?) -> Color {
        guard let area = area else { return Color.gray.opacity(0.2) }
        return areaTypeColors[area.type] ?? .green
    }
    
    func areaAbbreviation(_ area: CropArea) -> String {
        // Create abbreviation from area name
        let words = area.name.split(separator: " ")
        if words.count == 1 {
            return String(words[0].prefix(3)).uppercased()
        }
        return words.map { String($0.prefix(1)).uppercased() }.joined()
    }
    
    func saveMap() {
        // Convert GridPosition keys to strings for UserDefaults
        let stringDict = Dictionary(uniqueKeysWithValues: 
            mapAssignments.map { (key, value) in 
                (key.stringValue, value ?? "") 
            }
        )
        UserDefaults.standard.setValue(["rows": rows, "columns": columns, "assignments": stringDict], forKey: "landMapPrototype")
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
    
    func loadAreas() {
        guard let farmId = farmService.currentFarmId else { return }
        isLoading = true
        
        Task {
            do {
                cropAreas = try await farmService.loadCropAreas(farmId: farmId)
                print("✅ Loaded \(cropAreas.count) crop areas for map")
            } catch {
                print("❌ Failed to load crop areas: \(error)")
            }
            isLoading = false
        }
    }
    
    var legendView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Legend:").bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CropAreaType.allCases, id: \.self) { type in
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(areaTypeColors[type] ?? .gray)
                                .frame(width: 18, height: 18)
                                .cornerRadius(3)
                            Text(type.displayName)
                                .font(.caption)
                        }
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 18, height: 18).cornerRadius(3)
                        Text("Unassigned").font(.caption)
                    }
                }
            }
        }
    }
}

struct LandMapBoxView: View {
    let pos: GridPosition
    let area: CropArea?
    let isSelected: Bool
    let boxSize: CGFloat
    let onTap: () -> Void
    let boxColor: (CropArea?) -> Color
    let areaAbbreviation: (CropArea) -> String
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(boxColor(area))
                .frame(width: boxSize, height: boxSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.2), lineWidth: isSelected ? 3 : 1)
                )
                .onTapGesture { onTap() }
            if let area = area {
                Text(areaAbbreviation(area))
                    .font(.caption2)
                    .foregroundColor(.white)
                    .bold()
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
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

struct AreaPickerView: View {
    let areas: [CropArea]
    var onSelect: (CropArea?) -> Void
    var onClear: () -> Void
    
    // Colors for different area types
    let areaTypeColors: [CropAreaType: Color] = [
        .greenhouse: .green,
        .highTunnel: .blue,
        .outdoorBeds: .brown,
        .seedHouse: .orange,
        .treeCrops: .purple
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Assign Crop Area")) {
                    ForEach(areas) { area in
                        Button(action: { onSelect(area) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(area.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(area.type.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background((areaTypeColors[area.type] ?? .green).opacity(0.2))
                                            .cornerRadius(4)
                                        
                                        if let dimensions = area.dimensions {
                                            Text(dimensions)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Rectangle()
                                    .fill(areaTypeColors[area.type] ?? .green)
                                    .frame(width: 18, height: 18)
                                    .cornerRadius(3)
                            }
                        }
                    }
                    Button("Clear Assignment", role: .destructive, action: { onClear() })
                }
            }
            .navigationTitle("Select Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onSelect(nil) } } }
        }
    }
}

struct LandMapView_Previews: PreviewProvider {
    static var previews: some View {
        LandMapView()
            .environmentObject(FarmDataService.shared)
    }
}
