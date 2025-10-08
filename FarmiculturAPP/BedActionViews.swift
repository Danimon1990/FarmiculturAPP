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
    @EnvironmentObject var farmService: FarmDataService
    @State private var tasks: [BedTask] = []
    @State private var cropAreas: [CropArea] = []
    @State private var showingAddTask = false
    @State private var isLoading = false
    @State private var filterCompleted = false

    var filteredTasks: [BedTask] {
        if filterCompleted {
            return tasks.filter { $0.isCompleted }
        } else {
            return tasks
        }
    }

    var incompleteTasks: [BedTask] {
        tasks.filter { !$0.isCompleted }
    }

    var completedTasks: [BedTask] {
        tasks.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationView {
            List {
                // Summary section
                if !tasks.isEmpty {
                    Section(header: Text("Summary")) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(incompleteTasks.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Active Tasks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text("\(completedTasks.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Active tasks
                if !incompleteTasks.isEmpty {
                    Section(header: Text("Active Tasks")) {
                        ForEach(incompleteTasks.sorted(by: { task1, task2 in
                            // Sort by priority then due date
                            if task1.priority != task2.priority {
                                return priorityValue(task1.priority) > priorityValue(task2.priority)
                            }
                            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                                return date1 < date2
                            }
                            return task1.createdDate > task2.createdDate
                        })) { task in
                            TaskRowView(task: task, onToggle: {
                                toggleTaskCompletion(task)
                            })
                        }
                    }
                }

                // Completed tasks
                if !completedTasks.isEmpty {
                    Section(header: Text("Completed Tasks")) {
                        ForEach(completedTasks.sorted(by: { ($0.completedDate ?? $0.createdDate) > ($1.completedDate ?? $1.createdDate) })) { task in
                            TaskRowView(task: task, onToggle: {
                                toggleTaskCompletion(task)
                            })
                        }
                    }
                }

                // Empty state
                if tasks.isEmpty && !isLoading {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No tasks yet")
                                .font(.headline)
                            Text("Tap + to create your first task")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(tasks: $tasks, cropAreas: cropAreas)
            }
            .onAppear {
                loadTasks()
            }
        }
    }

    func priorityValue(_ priority: TaskPriority) -> Int {
        switch priority {
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }

    func loadTasks() {
        guard let farmId = farmService.currentFarmId else { return }
        isLoading = true

        Task {
            do {
                // Load crop areas for task assignment
                cropAreas = try await farmService.loadCropAreas(farmId: farmId)

                // Load all tasks
                tasks = try await farmService.loadTasks(farmId: farmId)
                print("✅ Loaded \(tasks.count) tasks")
            } catch {
                print("❌ Failed to load tasks: \(error)")
            }
            isLoading = false
        }
    }

    func toggleTaskCompletion(_ task: BedTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].isCompleted.toggle()
        tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil

        Task {
            do {
                try await farmService.updateTask(tasks[index])
                print("✅ Task completion toggled: \(task.title)")
            } catch {
                print("❌ Failed to update task: \(error)")
                // Revert on error
                tasks[index].isCompleted.toggle()
                tasks[index].completedDate = nil
            }
        }
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: BedTask
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)

                // Description
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Metadata
                HStack(spacing: 8) {
                    // Priority badge
                    Text(task.priority.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.2))
                        .foregroundColor(task.priority.color)
                        .cornerRadius(4)

                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                            Text(dueDate, format: .dateTime.month().day())
                        }
                        .font(.caption)
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? .red : .secondary)
                    }

                    // Assigned to
                    if let assignedTo = task.assignedTo {
                        Label(assignedTo, systemImage: "person")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Completed date
                if let completedDate = task.completedDate {
                    Text("Completed \(completedDate, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(task.isCompleted ? 0.6 : 1.0)
    }
}

// MARK: - Add Task View

struct AddTaskView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    @Binding var tasks: [BedTask]
    let cropAreas: [CropArea]
    let preselectedCropAreaId: String?

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedCropAreaId: String? = nil
    @State private var assignedToName = ""
    @State private var isSaving = false

    init(tasks: Binding<[BedTask]>, cropAreas: [CropArea], preselectedCropAreaId: String? = nil) {
        self._tasks = tasks
        self.cropAreas = cropAreas
        self.preselectedCropAreaId = preselectedCropAreaId
        // Initialize selectedCropAreaId with preselected value
        _selectedCropAreaId = State(initialValue: preselectedCropAreaId)
    }

    var body: some View {
        NavigationView {
            Form {
                // Task details
                Section(header: Text("Task Details")) {
                    TextField("Task Title", text: $title)
                        .font(.headline)

                    TextEditor(text: $taskDescription)
                        .frame(height: 100)
                        .overlay(
                            Group {
                                if taskDescription.isEmpty {
                                    Text("Description (optional)")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                // Priority
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Text(priority.displayName)
                                Spacer()
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Due date
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    }
                }

                // Location (Crop Area)
                Section(header: Text("Location (Optional)")) {
                    if preselectedCropAreaId != nil {
                        if let selectedArea = cropAreas.first(where: { $0.id == selectedCropAreaId }) {
                            HStack {
                                Image(systemName: selectedArea.type.icon)
                                    .foregroundColor(.blue)
                                Text(selectedArea.name)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("Pre-selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Picker("Change Crop Area", selection: $selectedCropAreaId) {
                            Text("None").tag(nil as String?)
                            ForEach(cropAreas) { area in
                                HStack {
                                    Image(systemName: area.type.icon)
                                    Text(area.name)
                                }
                                .tag(area.id as String?)
                            }
                        }
                    } else {
                        Picker("Crop Area", selection: $selectedCropAreaId) {
                            Text("None").tag(nil as String?)
                            ForEach(cropAreas) { area in
                                HStack {
                                    Image(systemName: area.type.icon)
                                    Text(area.name)
                                }
                                .tag(area.id as String?)
                            }
                        }
                    }
                }

                // Assignment
                Section(header: Text("Assignment (Optional)")) {
                    TextField("Worker Name", text: $assignedToName)
                        .autocapitalization(.words)
                }

                // Save button
                Section {
                    Button(action: saveTask) {
                        if isSaving {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Task")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func saveTask() {
        isSaving = true

        var task = BedTask(
            cropAreaId: selectedCropAreaId,
            title: title,
            taskDescription: taskDescription.isEmpty ? nil : taskDescription,
            dueDate: hasDueDate ? dueDate : nil,
            assignedTo: assignedToName.isEmpty ? nil : assignedToName,
            createdBy: farmService.currentFarmUser?.displayName,
            priority: priority
        )

        Task {
            do {
                try await farmService.createTask(task)
                tasks.append(task)
                print("✅ Task created: \(task.title)")
                dismiss()
            } catch {
                print("❌ Failed to create task: \(error)")
            }
            isSaving = false
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

