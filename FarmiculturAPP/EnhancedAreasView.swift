//
//  EnhancedAreasView.swift
//  FarmiculturAPP
//
//  Enhanced Areas view with integrated map and beds list
//

import SwiftUI

struct EnhancedAreasView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var cropAreas: [CropArea] = []
    @State private var isLoading = false
    @State private var showingAddArea = false
    @State private var showingAllBeds = false
    @State private var isEditingMap = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Map Section
                    mapSection

                    Divider()
                        .padding(.vertical, 16)

                    // Crop Areas List Section
                    areasListSection

                    // View All Beds Button
                    viewAllBedsButton
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("Farm Areas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddArea = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: signOut) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingAddArea) {
                AddCropAreaView(cropAreas: $cropAreas)
            }
            .sheet(isPresented: $showingAllBeds) {
                AllBedsView()
            }
            .onAppear {
                loadCropAreas()
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Farm Map")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { isEditingMap.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isEditingMap ? "checkmark.circle.fill" : "pencil.circle")
                        Text(isEditingMap ? "Done" : "Edit")
                            .font(.subheadline)
                    }
                    .foregroundColor(isEditingMap ? .green : .blue)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Compact Map View
            CompactLandMapView(isEditMode: $isEditingMap, cropAreas: $cropAreas)
                .frame(height: 300)
                .padding(.horizontal)

            if !isEditingMap {
                Text("Tap a square to view that area's details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Areas List Section

    private var areasListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crop Areas")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if cropAreas.isEmpty {
                emptyAreasView
            } else {
                ForEach(cropAreas) { area in
                    NavigationLink(destination: AreaDetailView(area: area)) {
                        CropAreaCardView(area: area)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
    }

    private var emptyAreasView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Crop Areas Yet")
                .font(.headline)
            Text("Tap + to create your first growing area")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - View All Beds Button

    private var viewAllBedsButton: some View {
        Button(action: { showingAllBeds = true }) {
            HStack {
                Image(systemName: "square.grid.3x3")
                    .font(.title3)
                Text("View All Beds")
                    .font(.headline)
                Spacer()
                Text("Organize by status or location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    func loadCropAreas() {
        guard let farmId = farmService.currentFarmId else { return }
        isLoading = true

        Task {
            do {
                cropAreas = try await farmService.loadCropAreas(farmId: farmId)
            } catch {
                print("Failed to load areas: \(error)")
            }
            isLoading = false
        }
    }

    func signOut() {
        farmService.signOut()
    }
}

// MARK: - Crop Area Card View

struct CropAreaCardView: View {
    let area: CropArea

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: area.type.icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(area.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(area.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let dimensions = area.dimensions {
                    Text(dimensions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Compact Land Map View

struct CompactLandMapView: View {
    @Binding var isEditMode: Bool
    @Binding var cropAreas: [CropArea]
    @EnvironmentObject var farmService: FarmDataService

    @State private var rows: Int = 6
    @State private var columns: Int = 8
    @State private var selected: GridPosition? = nil
    @State private var mapAssignments: [GridPosition: String] = [:] // GridPosition -> CropArea.id
    @State private var showAreaPicker = false
    @State private var selectedAreaForNavigation: CropArea? = nil
    @State private var showAreaDetail = false

    // Colors for different area types
    let areaTypeColors: [CropAreaType: Color] = [
        .greenhouse: .green,
        .highTunnel: .blue,
        .outdoorBeds: .brown,
        .seedHouse: .orange,
        .treeCrops: .purple
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Grid size controls (only in edit mode)
            if isEditMode {
                HStack(spacing: 16) {
                    Stepper("Rows: \(rows)", value: $rows, in: 1...12)
                        .font(.caption)
                    Stepper("Cols: \(columns)", value: $columns, in: 1...16)
                        .font(.caption)
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // The grid
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let availableHeight = isEditMode ? geometry.size.height - 60 : geometry.size.height
                let boxSize = min(availableWidth / CGFloat(columns), availableHeight / CGFloat(rows)) - 4

                VStack(spacing: 2) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<columns, id: \.self) { col in
                                let pos = GridPosition(row: row, col: col)
                                let area = mapAssignments[pos].flatMap { id in cropAreas.first { $0.id == id } }

                                MapBoxView(
                                    position: pos,
                                    area: area,
                                    boxSize: boxSize,
                                    isEditMode: isEditMode,
                                    areaTypeColors: areaTypeColors,
                                    onTap: {
                                        handleBoxTap(pos: pos, area: area)
                                    }
                                )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Save button (only in edit mode)
            if isEditMode {
                Button(action: saveMap) {
                    Text("Save Map")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showAreaPicker) {
            if let selectedPos = selected {
                AreaPickerSheet(
                    cropAreas: cropAreas,
                    selectedPosition: selectedPos,
                    currentAreaId: mapAssignments[selectedPos],
                    onSelect: { areaId in
                        if let areaId = areaId {
                            mapAssignments[selectedPos] = areaId
                        } else {
                            mapAssignments.removeValue(forKey: selectedPos)
                        }
                        showAreaPicker = false
                    }
                )
            }
        }
        .background(
            NavigationLink(
                destination: selectedAreaForNavigation.map { AreaDetailView(area: $0) },
                isActive: $showAreaDetail
            ) {
                EmptyView()
            }
            .hidden()
        )
        .onAppear {
            loadMap()
        }
        .animation(.spring(), value: isEditMode)
    }

    private func handleBoxTap(pos: GridPosition, area: CropArea?) {
        if isEditMode {
            selected = pos
            showAreaPicker = true
        } else if let area = area {
            // Navigate to area detail
            selectedAreaForNavigation = area
            showAreaDetail = true
        }
    }

    private func saveMap() {
        guard let farmId = farmService.currentFarmId else { return }

        Task {
            do {
                // Convert to JSON for storage
                let encoder = JSONEncoder()
                let data = try encoder.encode(mapAssignments)
                let jsonString = String(data: data, encoding: .utf8) ?? "{}"

                // Save to UserDefaults for now (could be moved to Firestore)
                UserDefaults.standard.set(jsonString, forKey: "farmMap_\(farmId)")
                UserDefaults.standard.set(rows, forKey: "farmMapRows_\(farmId)")
                UserDefaults.standard.set(columns, forKey: "farmMapCols_\(farmId)")

                print("✅ Map saved successfully")
            } catch {
                print("❌ Failed to save map: \(error)")
            }
        }
    }

    private func loadMap() {
        guard let farmId = farmService.currentFarmId else { return }

        // Load from UserDefaults
        if let jsonString = UserDefaults.standard.string(forKey: "farmMap_\(farmId)"),
           let data = jsonString.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                mapAssignments = try decoder.decode([GridPosition: String].self, from: data)
            } catch {
                print("Failed to load map: \(error)")
            }
        }

        rows = UserDefaults.standard.integer(forKey: "farmMapRows_\(farmId)")
        if rows == 0 { rows = 6 }

        columns = UserDefaults.standard.integer(forKey: "farmMapCols_\(farmId)")
        if columns == 0 { columns = 8 }
    }
}

// MARK: - Map Box View

struct MapBoxView: View {
    let position: GridPosition
    let area: CropArea?
    let boxSize: CGFloat
    let isEditMode: Bool
    let areaTypeColors: [CropAreaType: Color]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let area = area {
                    areaTypeColors[area.type, default: .gray]
                        .opacity(0.8)

                    if boxSize > 30 {
                        VStack(spacing: 2) {
                            Text(areaAbbreviation(area))
                                .font(.system(size: min(boxSize / 4, 12), weight: .bold))
                                .foregroundColor(.white)

                            if boxSize > 50 {
                                Image(systemName: area.type.icon)
                                    .font(.system(size: min(boxSize / 5, 14)))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                } else {
                    Color(.systemGray6)

                    if isEditMode && boxSize > 30 {
                        Image(systemName: "plus")
                            .font(.system(size: min(boxSize / 3, 16)))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .frame(width: boxSize, height: boxSize)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isEditMode ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func areaAbbreviation(_ area: CropArea) -> String {
        let words = area.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        } else if let first = words.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Area Picker Sheet

struct AreaPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    let cropAreas: [CropArea]
    let selectedPosition: GridPosition
    let currentAreaId: String?
    let onSelect: (String?) -> Void

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { onSelect(nil); dismiss() }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                            Text("Clear Assignment")
                        }
                    }
                }

                Section("Assign Crop Area") {
                    ForEach(cropAreas) { area in
                        Button(action: { onSelect(area.id); dismiss() }) {
                            HStack {
                                Image(systemName: area.type.icon)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text(area.name)
                                        .foregroundColor(.primary)
                                    Text(area.type.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if currentAreaId == area.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct EnhancedAreasView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedAreasView()
            .environmentObject(FarmDataService.shared)
    }
}
