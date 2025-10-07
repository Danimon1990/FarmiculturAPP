//
//  BedActionViews.swift
//  FarmiculturAPP
//
//  Forms for bed actions: status change, plant info, harvest report
//

import SwiftUI

// MARK: - Change Status

struct ChangeStatusView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    @Binding var bed: Bed
    let area: CropArea
    let section: CropSection
    
    @State private var selectedStatus: BedStatus
    @State private var notes = ""
    @State private var isSaving = false
    
    init(bed: Binding<Bed>, area: CropArea, section: CropSection) {
        self._bed = bed
        self.area = area
        self.section = section
        self._selectedStatus = State(initialValue: bed.wrappedValue.status)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Status")) {
                    HStack {
                        Text(bed.status.displayName)
                        Spacer()
                        Circle()
                            .fill(bed.status.color)
                            .frame(width: 20, height: 20)
                    }
                }
                
                Section(header: Text("New Status")) {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(BedStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: status.icon)
                                Text(status.displayName)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveStatusChange) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Update Status")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedStatus == bed.status || isSaving)
                }
            }
            .navigationTitle("Change Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func saveStatusChange() {
        isSaving = true
        
        bed.addStatusChange(
            to: selectedStatus,
            by: farmService.currentFarmUser?.displayName,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                try await farmService.updateBed(bed, in: section.id, areaId: area.id)
                dismiss()
            } catch {
                print("Failed to update bed: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - Edit Plant Info

struct EditPlantInfoView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    @Binding var bed: Bed
    let area: CropArea
    let section: CropSection
    
    @State private var cropName: String = ""
    @State private var varieties: [PlantVariety] = []
    @State private var startMethod: StartMethod = .transplanted
    @State private var datePlanted = Date()
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Crop Information")) {
                    TextField("Crop Name (e.g., 'Spinach Spring 2025')", text: $cropName)
                        .font(.headline)
                }

                Section(header: Text("Planting Information")) {
                    Picker("Start Method", selection: $startMethod) {
                        ForEach([StartMethod.directSeed, StartMethod.transplanted], id: \.self) { method in
                            HStack {
                                Image(systemName: method.icon)
                                Text(method.displayName)
                            }
                            .tag(method)
                        }
                    }

                    DatePicker("Date Planted", selection: $datePlanted, displayedComponents: [.date])
                }
                
                Section(header: Text("Varieties")) {
                    ForEach($varieties) { $variety in
                        VarietyEditorRow(variety: $variety)
                    }
                    .onDelete(perform: deleteVariety)
                    
                    Button(action: addVariety) {
                        Label("Add Variety", systemImage: "plus.circle")
                    }
                }
                
                Section {
                    Button(action: savePlantInfo) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Plant Information")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Plant Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Load existing crop name
                cropName = bed.currentCropName ?? ""

                if let method = bed.startMethod {
                    startMethod = method
                }
                if let date = bed.datePlanted {
                    datePlanted = date
                }
                varieties = bed.varieties

                // Add a default variety if none exist
                if varieties.isEmpty {
                    varieties.append(PlantVariety(name: "", count: 0))
                }
            }
        }
    }
    
    func addVariety() {
        varieties.append(PlantVariety(name: "", count: 0))
    }
    
    func deleteVariety(at offsets: IndexSet) {
        varieties.remove(atOffsets: offsets)
    }
    
    
    func savePlantInfo() {
        isSaving = true

        print("🌱 savePlantInfo called")
        print("🌱 Crop name: '\(cropName)'")
        print("🌱 Current varieties array count: \(varieties.count)")
        for (index, variety) in varieties.enumerated() {
            print("🌱 Variety \(index): name='\(variety.name)' count=\(variety.count)")
        }

        // Save crop name
        bed.currentCropName = cropName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : cropName

        bed.startMethod = startMethod
        bed.datePlanted = datePlanted

        // Filter out empty varieties (no name and no count)
        let validVarieties = varieties.filter { variety in
            let hasName = !variety.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasCount = variety.count > 0
            print("🌱 Checking variety '\(variety.name)': hasName=\(hasName), hasCount=\(hasCount)")
            return hasName || hasCount
        }

        bed.varieties = validVarieties

        print("🌱 Saving plant info:")
        print("   - Crop name saved: '\(bed.currentCropName ?? "nil")'")
        print("   - Total varieties entered: \(varieties.count)")
        print("   - Valid varieties (filtered): \(validVarieties.count)")
        print("   - Varieties: \(validVarieties.map { "'\($0.name)': \($0.count)" }.joined(separator: ", "))")
        print("🌱 bed.varieties count after assignment: \(bed.varieties.count)")

        // Calculate expected harvest dates based on varieties
        if let earliestMaturity = validVarieties.compactMap({ $0.daysToMaturity }).min() {
            bed.expectedHarvestStart = Calendar.current.date(byAdding: .day, value: earliestMaturity, to: datePlanted)
        }

        if validVarieties.contains(where: { $0.continuousHarvest }) {
            // If any variety is continuous, set an end date
            if let latestMaturity = validVarieties.compactMap({ $0.daysToMaturity }).max() {
                bed.expectedHarvestEnd = Calendar.current.date(byAdding: .day, value: latestMaturity + 90, to: datePlanted)
            }
        }

        // Update status if needed
        if bed.status == .dirty || bed.status == .clean || bed.status == .prepared {
            bed.addStatusChange(
                to: .planted,
                by: farmService.currentFarmUser?.displayName,
                notes: "Added plant information"
            )
        }

        Task {
            do {
                print("🔄 Calling updateBed for bed \(bed.bedNumber)")
                print("🔄 About to save bed with:")
                print("   - currentCropName: '\(bed.currentCropName ?? "nil")'")
                print("   - varieties count: \(bed.varieties.count)")
                print("   - startMethod: \(bed.startMethod?.rawValue ?? "nil")")
                print("   - datePlanted: \(bed.datePlanted?.description ?? "nil")")
                for (i, variety) in bed.varieties.enumerated() {
                    print("   - Variety \(i): name='\(variety.name)', count=\(variety.count)")
                }

                try await farmService.updateBed(bed, in: section.id, areaId: area.id)
                print("✅ Plant info saved successfully")
                dismiss()
            } catch {
                print("❌ Failed to update bed: \(error)")
            }
            isSaving = false
        }
    }
}

struct VarietyEditorRow: View {
    @Binding var variety: PlantVariety
    
    var body: some View {
        VStack(spacing: 8) {
            TextField("Variety Name (optional)", text: $variety.name)
            
            HStack {
                Text("Count:")
                TextField("0", value: $variety.count, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                
                Spacer()
                
                Text("Days to Maturity:")
                TextField("65", value: $variety.daysToMaturity, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            .font(.caption)
            
            Toggle("Continuous Harvest", isOn: $variety.continuousHarvest)
                .font(.caption)
            
            if variety.continuousHarvest {
                HStack {
                    Text("Harvest Window (days):")
                    TextField("90", value: $variety.harvestWindowDays, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Harvest Report

struct HarvestReportView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    @Binding var bed: Bed
    let area: CropArea
    let section: CropSection
    
    @State private var quantity: Double = 0
    @State private var selectedUnit: HarvestUnit = .kilograms
    @State private var selectedQuality: HarvestQuality = .good
    @State private var selectedVarieties: Set<String> = []
    @State private var notes = ""
    @State private var workerName = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Harvest Details")) {
                    HStack {
                        Text("Quantity:")
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(HarvestUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    
                    Picker("Quality", selection: $selectedQuality) {
                        ForEach(HarvestQuality.allCases, id: \.self) { quality in
                            HStack {
                                Image(systemName: quality.icon)
                                Text(quality.displayName)
                            }
                            .tag(quality)
                        }
                    }
                }
                
                if !bed.varieties.isEmpty {
                    Section(header: Text("Varieties Harvested")) {
                        ForEach(bed.varieties) { variety in
                            Button(action: {
                                if selectedVarieties.contains(variety.name) {
                                    selectedVarieties.remove(variety.name)
                                } else {
                                    selectedVarieties.insert(variety.name)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedVarieties.contains(variety.name) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedVarieties.contains(variety.name) ? .green : .gray)
                                    Text(variety.name)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Reporter Information")) {
                    TextField("Worker Name", text: $workerName)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section {
                    Button(action: saveHarvestReport) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Submit Harvest Report")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(quantity <= 0 || workerName.isEmpty || isSaving)
                }
            }
            .navigationTitle("Report Harvest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                workerName = farmService.currentFarmUser?.displayName ?? ""
                if !bed.varieties.isEmpty {
                    selectedVarieties = Set(bed.varieties.map { $0.name })
                }
            }
        }
    }
    
    func saveHarvestReport() {
        isSaving = true
        
        let report = HarvestReport(
            bedId: bed.id,
            reportedBy: workerName,
            quantity: quantity,
            unit: selectedUnit,
            quality: selectedQuality,
            notes: notes.isEmpty ? nil : notes,
            varieties: Array(selectedVarieties)
        )
        
        Task {
            do {
                try await farmService.addHarvestReport(report, to: bed, sectionId: section.id, areaId: area.id)
                bed.addHarvestReport(report)
                
                // Update status to harvesting if needed
                if bed.status == .growing {
                    bed.addStatusChange(
                        to: .harvesting,
                        by: workerName,
                        notes: "First harvest reported"
                    )
                    try await farmService.updateBed(bed, in: section.id, areaId: area.id)
                }
                
                dismiss()
            } catch {
                print("Failed to save harvest report: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - All Beds View

struct AllBedsView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var allBeds: [Bed] = []
    @State private var cropAreas: [CropArea] = []
    @State private var sections: [CropSection] = []
    @State private var isLoading = false
    @State private var selectedFilter: BedStatus? = nil
    
    var filteredBeds: [Bed] {
        if let filter = selectedFilter {
            return allBeds.filter { $0.status == filter }
        }
        return allBeds
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", count: allBeds.count, isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        
                        ForEach(BedStatus.allCases, id: \.self) { status in
                            let count = allBeds.filter { $0.status == status }.count
                            if count > 0 {
                                FilterPill(title: status.displayName, count: count, color: status.color, isSelected: selectedFilter == status) {
                                    selectedFilter = status
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                List {
                    ForEach(filteredBeds) { bed in
                        if let area = cropAreas.first(where: { $0.id == bed.cropAreaId }),
                           let section = sections.first(where: { $0.id == bed.sectionId }) {
                            NavigationLink(destination: BedDetailView(bed: Binding(
                                get: { bed },
                                set: { newBed in
                                    print("🔄 Updating bed in AllBedsView: \(newBed.bedNumber)")
                                    if let index = allBeds.firstIndex(where: { $0.id == bed.id }) {
                                        allBeds[index] = newBed
                                        print("✅ Bed updated in AllBedsView at index \(index)")
                                    } else {
                                        print("❌ Bed not found in AllBedsView")
                                    }
                                }
                            ), area: area, section: section)) {
                                BedRowView(bed: bed)
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Beds")
            .onAppear {
                loadAllData()
            }
        }
    }
    
    func loadAllData() {
        guard let farmId = farmService.currentFarmId else { return }
        isLoading = true
        
        Task {
            do {
                cropAreas = try await farmService.loadCropAreas(farmId: farmId)
                
                var tempBeds: [Bed] = []
                var tempSections: [CropSection] = []
                
                for area in cropAreas {
                    let areaSections = try await farmService.loadSections(farmId: farmId, areaId: area.id)
                    tempSections.append(contentsOf: areaSections)
                    
                    let areaBeds = try await farmService.loadAllBeds(farmId: farmId, areaId: area.id)
                    tempBeds.append(contentsOf: areaBeds)
                }
                
                allBeds = tempBeds
                sections = tempSections
            } catch {
                print("Failed to load data: \(error)")
            }
            isLoading = false
        }
    }
}

struct FilterPill: View {
    let title: String
    let count: Int
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text("(\(count))")
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

// MARK: - Harvest Dashboard

struct HarvestDashboardView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Harvest dashboard coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Harvest")
        }
    }
}

// MARK: - Tasks View

struct TasksView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Tasks view coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Tasks")
        }
    }
}

// MARK: - Bed Row View

struct BedRowView: View {
    let bed: Bed
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bed \(bed.bedNumber)")
                    .font(.headline)
                
                if !bed.varieties.isEmpty {
                    if bed.varieties.count == 1 {
                        Text(bed.varieties[0].name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(bed.varieties.count) varieties")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text(bed.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(bed.status.color.opacity(0.2))
                        .cornerRadius(4)
                    
                    if bed.totalPlantCount > 0 {
                        Text("\(bed.totalPlantCount) plants")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if bed.totalHarvested > 0 {
                        Text("\(bed.totalHarvested, specifier: "%.1f") harvested")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Circle()
                    .fill(bed.status.color)
                    .frame(width: 12, height: 12)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

