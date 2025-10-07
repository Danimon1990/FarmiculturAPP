//
//  AreaDetailView.swift
//  FarmiculturAPP
//
//  Area detail view with sections and bed management
//

import SwiftUI

struct AreaDetailView: View {
    @EnvironmentObject var farmService: FarmDataService
    let area: CropArea
    
    @State private var sections: [CropSection] = []
    @State private var allBeds: [Bed] = []
    @State private var showingAddSection = false
    @State private var isLoading = false
    @State private var sectionToDelete: CropSection?
    @State private var showingDeleteSectionAlert = false
    @State private var showingDeleteAreaAlert = false
    @State private var selectedBed: Bed?
    @State private var showingBedDetail = false
    
    var body: some View {
        List {
            // Sections with Bed Matrices
            ForEach(sections) { cropSection in
                Section(header: HStack {
                    Text(cropSection.name)
                    Spacer()
                    Text("\(bedCount(for: cropSection)) beds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        deleteSection(cropSection)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        deleteSection(cropSection)
                    } label: {
                        Label("Delete Section", systemImage: "trash")
                    }
                }) {
                    let sectionBeds = allBeds.filter { $0.sectionId == cropSection.id }
                    if sectionBeds.isEmpty {
                        Text("No beds in this section")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        BedMatrixView(beds: .constant(sectionBeds), area: area, section: cropSection, onBedSelected: { bed in
                            selectedBed = bed
                            showingBedDetail = true
                        })
                    }
                }
            }
            
            // Statistics (moved below bed matrices)
            Section(header: Text("Statistics")) {
                LabeledContent("Total Beds", value: "\(allBeds.count)")
                LabeledContent("Active Beds", value: "\(activeBedCount)")
                LabeledContent("Harvesting", value: "\(harvestingBedCount)")
                LabeledContent("Total Plants", value: "\(totalPlantCount)")
                
                if !growingPlantNames.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plants Growing:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ForEach(growingPlantNames, id: \.self) { plantName in
                            Text("• \(plantName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Add Section Button
            Section {
                Button(action: { showingAddSection = true }) {
                    Label("Add Section", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingAddSection = true }) {
                        Label("Add Section", systemImage: "plus")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAreaAlert = true }) {
                        Label("Delete Area", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionView(area: area, sections: $sections)
        }
        .sheet(isPresented: $showingBedDetail, onDismiss: {
            // Reload beds when sheet is dismissed to get latest data from Firebase
            print("🔄 Bed detail sheet dismissed, reloading beds...")
            loadSections()
        }) {
            if let bed = selectedBed, let section = sections.first(where: { $0.id == bed.sectionId }) {
                NavigationView {
                    BedDetailView(bed: Binding(
                        get: {
                            // Always return the latest version from selectedBed
                            selectedBed ?? bed
                        },
                        set: { newBed in
                            print("🔄 Updating bed in AreaDetailView: \(newBed.bedNumber)")
                            // Update the bed in the allBeds array
                            if let index = allBeds.firstIndex(where: { $0.id == newBed.id }) {
                                allBeds[index] = newBed
                                print("✅ Bed updated in allBeds array at index \(index)")
                            } else {
                                print("❌ Bed not found in allBeds array")
                            }
                            selectedBed = newBed
                        }
                    ), area: area, section: section)
                }
            }
        }
        .alert("Delete Section", isPresented: $showingDeleteSectionAlert) {
            Button("Cancel", role: .cancel) {
                sectionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let section = sectionToDelete {
                    performDeleteSection(section)
                }
            }
        } message: {
            if let section = sectionToDelete {
                Text("Are you sure you want to delete '\(section.name)'? This will also delete all \(bedCount(for: section)) beds in this section. This action cannot be undone.")
            }
        }
        .alert("Delete Area", isPresented: $showingDeleteAreaAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                performDeleteArea()
            }
        } message: {
            Text("Are you sure you want to delete '\(area.name)'? This will also delete all \(sections.count) sections and \(allBeds.count) beds in this area. This action cannot be undone.")
        }
        .onAppear {
            loadSections()
        }
    }
    
    var activeBedCount: Int {
        allBeds.filter { $0.status != .dirty && $0.status != .clean }.count
    }
    
    var harvestingBedCount: Int {
        allBeds.filter { $0.status == .harvesting }.count
    }
    
    var totalPlantCount: Int {
        allBeds.reduce(0) { $0 + $1.totalPlantCount }
    }
    
    var growingPlantNames: [String] {
        let activeBeds = allBeds.filter { $0.status != .dirty && $0.status != .clean }
        let varietyNames = activeBeds.flatMap { bed in
            bed.varieties.map { $0.name }
        }
        return Array(Set(varietyNames)).sorted()
    }
    
    func bedCount(for section: CropSection) -> Int {
        allBeds.filter { $0.sectionId == section.id }.count
    }
    
    func deleteSection(_ section: CropSection) {
        sectionToDelete = section
        showingDeleteSectionAlert = true
    }
    
    func performDeleteSection(_ section: CropSection) {
        Task {
            do {
                // Delete all beds in this section first
                let sectionBeds = allBeds.filter { $0.sectionId == section.id }
                for bed in sectionBeds {
                    try await farmService.deleteBed(bedId: bed.id, sectionId: section.id, areaId: area.id)
                }
                
                // Delete the section
                try await farmService.deleteSection(sectionId: section.id, areaId: area.id)
                
                // Update local data
                sections.removeAll { $0.id == section.id }
                allBeds.removeAll { $0.sectionId == section.id }
                
                print("✅ Deleted section: \(section.name)")
            } catch {
                print("❌ Failed to delete section: \(error)")
            }
        }
        sectionToDelete = nil
    }
    
    func performDeleteArea() {
        Task {
            do {
                // Delete all beds first
                for bed in allBeds {
                    try await farmService.deleteBed(bedId: bed.id, sectionId: bed.sectionId, areaId: area.id)
                }
                
                // Delete all sections
                for section in sections {
                    try await farmService.deleteSection(sectionId: section.id, areaId: area.id)
                }
                
                // Delete the area
                try await farmService.deleteCropArea(areaId: area.id)
                
                print("✅ Deleted area: \(area.name)")
                // Navigation will pop automatically
            } catch {
                print("❌ Failed to delete area: \(error)")
            }
        }
    }
    
    func loadSections() {
        guard let farmId = farmService.currentFarmId else { 
            print("❌ No farm ID for loading sections")
            return 
        }
        isLoading = true
        
        Task {
            do {
                print("🔄 Loading sections for area: \(area.name)")
                sections = try await farmService.loadSections(farmId: farmId, areaId: area.id)
                print("✅ Loaded \(sections.count) sections")
                
                // Load all beds for this area
                var tempBeds: [Bed] = []
                for section in sections {
                    print("🔄 Loading beds for section: \(section.name)")
                    let sectionBeds = try await farmService.loadBeds(farmId: farmId, areaId: area.id, sectionId: section.id)
                    print("✅ Found \(sectionBeds.count) beds in section \(section.name)")
                    tempBeds.append(contentsOf: sectionBeds)
                }
                allBeds = tempBeds
                print("✅ Total beds loaded: \(allBeds.count)")
            } catch {
                print("❌ Failed to load sections: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Section Row View

struct SectionRowView: View {
    let section: CropSection
    let bedCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(section.name)
                    .font(.headline)
                
                if let sectionNumber = section.sectionNumber {
                    Text("Section \(sectionNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(bedCount) beds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let dimensions = section.dimensions {
                        Text("• \(dimensions)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add Section View

struct AddSectionView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    let area: CropArea
    @Binding var sections: [CropSection]
    
    @State private var name = ""
    @State private var sectionNumber = ""
    @State private var dimensions = ""
    @State private var notes = ""
    @State private var numberOfBeds = 8
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Section Information")) {
                    TextField("Name (e.g., Section A, North Wing)", text: $name)
                    TextField("Section Number (optional)", text: $sectionNumber)
                    TextField("Dimensions (optional)", text: $dimensions)
                }
                
                Section(header: Text("Beds")) {
                    Stepper("Number of Beds: \(numberOfBeds)", value: $numberOfBeds, in: 1...50)
                    
                    // Show naming preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bed naming system:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        let sectionCode = generateSectionCode(from: sectionNumber, sectionName: name)
                        let bedNames = (1...min(5, numberOfBeds)).map { bedNum in
                            "\(area.name.uppercased())-\(sectionCode)-\(bedNum)"
                        }
                        
                        ForEach(bedNames, id: \.self) { bedName in
                            Text("• \(bedName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if numberOfBeds > 5 {
                            Text("• ... and \(numberOfBeds - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSection()
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveSection() {
        isSaving = true
        
        let section = CropSection(
            cropAreaId: area.id,
            name: name,
            sectionNumber: sectionNumber.isEmpty ? nil : sectionNumber,
            dimensions: dimensions.isEmpty ? nil : dimensions,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                // Create the section
                try await farmService.createSection(section, in: area.id)
                sections.append(section)
                
                // Create beds for this section with automatic naming
                let sectionCode = generateSectionCode(from: sectionNumber, sectionName: name)
                
                for i in 1...numberOfBeds {
                    let bedNumber = "\(area.name.uppercased())-\(sectionCode)-\(i)"
                    var bed = Bed(
                        sectionId: section.id,
                        cropAreaId: area.id,
                        bedNumber: bedNumber,
                        status: .dirty
                    )
                    
                    // Add initial status change
                    bed.addStatusChange(
                        to: .dirty,
                        by: farmService.currentFarmUser?.displayName,
                        notes: "Bed created"
                    )
                    
                    try await farmService.createBed(bed, in: section.id, areaId: area.id)
                }
                
                dismiss()
            } catch {
                print("Failed to save section: \(error)")
            }
            isSaving = false
        }
    }
    
    func generateSectionCode(from sectionNumber: String, sectionName: String) -> String {
        // If section number is provided, use it
        if !sectionNumber.isEmpty {
            return sectionNumber.uppercased()
        }
        
        // If no section number, generate from section name
        let words = sectionName.components(separatedBy: .whitespaces)
        if words.count == 1 {
            // Single word - take first 2 characters
            return String(words[0].prefix(2)).uppercased()
        } else {
            // Multiple words - take first letter of each word
            return words.compactMap { $0.first }.map { String($0) }.joined().uppercased()
        }
    }
}

// MARK: - Section Detail View

struct SectionDetailView: View {
    @EnvironmentObject var farmService: FarmDataService
    let area: CropArea
    let section: CropSection
    
    @State private var beds: [Bed] = []
    @State private var showingAddBed = false
    @State private var isLoading = false
    
    var body: some View {
        List {
            // Section Info
            Section(header: Text("Section Information")) {
                LabeledContent("Name", value: section.name)
                if let sectionNumber = section.sectionNumber {
                    LabeledContent("Section Number", value: sectionNumber)
                }
                if let dimensions = section.dimensions {
                    LabeledContent("Dimensions", value: dimensions)
                }
                if let notes = section.notes {
                    LabeledContent("Notes", value: notes)
                }
            }
            
            // Bed Matrix
            Section(header: Text("Beds (\(beds.count))")) {
                if beds.isEmpty {
                    Text("No beds in this section")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    BedMatrixView(beds: $beds, area: area, section: section, onBedSelected: { bed in
                        // Navigate to bed detail in section view
                        // This will be handled by NavigationLink in the section detail
                    })
                }
            }
        }
        .navigationTitle(section.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddBed = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBed) {
            AddBedView(area: area, section: section, beds: $beds)
        }
        .onAppear {
            loadBeds()
        }
    }
    
    func loadBeds() {
        guard let farmId = farmService.currentFarmId else { return }
        isLoading = true
        
        Task {
            do {
                beds = try await farmService.loadBeds(farmId: farmId, areaId: area.id, sectionId: section.id)
            } catch {
                print("Failed to load beds: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Add Bed View

struct AddBedView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    let area: CropArea
    let section: CropSection
    @Binding var beds: [Bed]
    
    @State private var bedNumber = ""
    @State private var notes = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bed Information")) {
                    TextField("Bed Number (e.g., A1, B3, 12)", text: $bedNumber)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Text("Bed will be created with status: Dirty")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Bed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBed()
                    }
                    .disabled(bedNumber.isEmpty || isSaving)
                }
            }
        }
    }
    
    func saveBed() {
        isSaving = true
        
        var bed = Bed(
            sectionId: section.id,
            cropAreaId: area.id,
            bedNumber: bedNumber,
            status: .dirty
        )
        
        if !notes.isEmpty {
            bed.notes = notes
        }
        
        // Add initial status change
        bed.addStatusChange(
            to: .dirty,
            by: farmService.currentFarmUser?.displayName,
            notes: "Bed created"
        )
        
        Task {
            do {
                try await farmService.createBed(bed, in: section.id, areaId: area.id)
                beds.append(bed)
                dismiss()
            } catch {
                print("Failed to save bed: \(error)")
            }
            isSaving = false
        }
    }
}

struct AreaDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let area = CropArea(farmId: "farm-1", name: "Greenhouse 1", type: .greenhouse)
        
        NavigationView {
            AreaDetailView(area: area)
                .environmentObject(FarmDataService.shared)
        }
    }
}
