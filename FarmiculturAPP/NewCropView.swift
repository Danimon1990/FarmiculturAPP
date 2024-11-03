import SwiftUI
/*
struct NewCropView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var crops: [Crop]
    
    @State private var type: CropType = .greenhouse
    @State private var name: String = ""
    @State private var isActive: Bool = true
    @State private var numberOfSections: Int = 1
    @State private var bedsPerSection: Int = 1
    @State private var sectionLength: Double = 0
    @State private var sectionWidth: Double = 0
    @State private var expectedHarvestDate: Date = Date()
    @State private var seedVariety: String = ""
    @State private var numberOfSeeds: Int = 0
    @State private var treeVariety: String = ""
    @State private var numberOfTrees: Int = 0
    @State private var numberOfSeedsText: String = ""  // Text input for number of seeds
    @State private var seedStartDate: Date = Date()   // Start date of seeds
    @State private var seedLocation: String = ""      // Location of the seeds
    @State private var potSizeText: String = ""       // Text input for pot size
    @State private var potSize: Double = 0.0          // Numeric pot size
    @State private var soilUsed: String = ""          // Type of soil used
    */
struct NewCropView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var crops: [Crop]
    @State private var totalSeeds: Int = 0
    @State private var type: CropType = .greenhouse
    @State private var name: String = ""
    @State private var isActive: Bool = true
    
    @State private var numberOfSections: Int = 1
    @State private var bedsPerSection: Int = 1
    @State private var sectionLength: Double = 0
    @State private var sectionWidth: Double = 0
    @State private var expectedHarvestDate: Date = Date()
    @State private var seedVariety: String = ""
    @State private var numberOfSeeds: Int = 0
    @State private var treeVariety: String = ""
    @State private var numberOfTrees: Int = 0
    @State private var numberOfSeedsText: String = ""  // Text input for number of seeds
    @State private var seedStartDate: Date = Date()   // Start date of seeds
    @State private var seedLocation: String = ""      // Location of the seeds
    @State private var potSizeText: String = ""       // Text input for pot size
    @State private var potSize: Double = 0.0          // Numeric pot size
    @State private var soilUsed: String = ""          // Type of soil used
    @State private var sections: [[Bed]] = [] // Sections for greenhouse crops
    @State private var beds: [Bed] = []      // Beds for greenhouse crops
    @State private var activities: [Activity] = [] // Activities related to the crop
    @State private var observations: [Observation] = [] // Observations for seeds or crops
    var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Crop Details")) {
                        Picker("Crop Type", selection: $type) {
                            ForEach(CropType.allCases, id: \.self) { type in
                                Text(type.rawValue)
                            }
                        }
                        TextField("Crop Name", text: $name)
                        Toggle("Currently Active", isOn: $isActive)
                    }
                    // Dynamic Layout Section
                    dynamicFieldsForType(type)

                    Section {
                        Button("Save") {
                            saveCrop()
                        }
                    }
                }
                .navigationTitle("Add New Crop")
                .navigationBarItems(leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }

    @ViewBuilder
    private func dynamicFieldsForType(_ type: CropType) -> some View {
        switch type {
        case .greenhouse, .highTunnels, .outdoorBeds:
            greenhouseLayoutFields
        case .treeCrops:
            treeCropFields
        case .seeds:
            seedFields
        }
    }
    // Greenhouse/High Tunnels/Outdoor Beds Layout
    private var greenhouseLayoutFields: some View {
        Section(header: Text("Greenhouse Layout")) {
            Stepper("Number of Sections: \(numberOfSections)", value: $numberOfSections, in: 1...10)
            Stepper("Beds Per Section: \(bedsPerSection)", value: $bedsPerSection, in: 1...20)
            
            HStack {
                        Text("Section Length (ft):")
                        TextField("Enter length", value: $sectionLength, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Section Width (ft):")
                        TextField("Enter width", value: $sectionWidth, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
        }
    }
    
    // Tree Crop Fields
    private var treeCropFields: some View {
        Section(header: Text("Tree Crop Details")) {
            TextField("Tree Variety", text: $treeVariety)
            Stepper("Number of Trees: \(numberOfTrees)", value: $numberOfTrees, in: 1...100)
        }
    }
    
    // Seed Fields
    private var seedFields: some View {
        Section(header: Text("Seed Details")) {
            TextField("Seed Variety", text: $seedVariety)
            
            HStack {
                Text("Number of Seeds:")
                TextField("Enter number", text: $numberOfSeedsText)
                    .keyboardType(.numberPad)
                    .onChange(of: numberOfSeedsText) {
                        if let number = Int(numberOfSeedsText), number > 0 {
                            numberOfSeeds = number
                        } else {
                            numberOfSeedsText = ""
                        }
                    }
            }

            DatePicker("Start Date", selection: $seedStartDate, displayedComponents: .date)

            TextField("Location (e.g., Greenhouse A)", text: $seedLocation)

            HStack {
                Text("Pot Size (inches):")
                TextField("Enter size", text: $potSizeText)
                    .keyboardType(.decimalPad)
                    .onChange(of: potSizeText) {
                        if let size = Double(potSizeText), size > 0 {
                            potSize = size
                        } else {
                            potSizeText = ""
                        }
                    }
            }

            TextField("Soil Used", text: $soilUsed)
        }
    }
    
    private func saveCrop() {
        guard !name.isEmpty else {
            print("Crop name is required.")
            return
        }

        // Create sections and beds based on the type
        let sections = (type == .greenhouse || type == .highTunnels || type == .outdoorBeds)
            ? (0..<numberOfSections).map { sectionIndex in
                (0..<bedsPerSection).map { bedIndex in
                    Bed(
                        id: UUID(),
                        section: sectionIndex + 1,
                        bed: bedIndex + 1,
                        plantCount: 0,
                        state: "Available"
                    )
                }
            }
            : []

        // Flatten sections to create a 1D array of beds if needed
        let beds = sections.flatMap { $0 }

        // Create the new crop with required fields
        let newCrop = Crop(
            id: UUID(),
            type: type,
            name: name,
            isActive: isActive,
            sections: sections, // Pass the 2D array here
            beds: [beds],         // Pass the 1D array here
            sectionLength: sectionLength,
            sectionWidth: sectionWidth,
            activities: activities,
            expectedHarvestDate: expectedHarvestDate,
            seedVariety: type == .seeds ? seedVariety : nil,
            numberOfSeeds: type == .seeds ? numberOfSeeds : nil,
            treeVariety: type == .treeCrops ? treeVariety : nil,
            numberOfTrees: type == .treeCrops ? numberOfTrees : nil,
            observations: observations,
            seedStartDate: type == .seeds ? seedStartDate : nil,
            seedLocation: type == .seeds ? seedLocation : nil,
            seedsPlanted: type == .seeds ? numberOfSeeds : 0,
            potSize: type == .seeds && potSize > 0 ? "\(potSize) inches" : nil,
            soilUsed: type == .seeds ? soilUsed : nil
        )

        // Append the crop to the list
        crops.append(newCrop)

        // Debugging
        print("New crop created: \(newCrop)")

        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
    }
    
    
    /*var body: some View {
        NavigationView {
            Form {
                // Crop Type Picker
                Section(header: Text("Crop Details")) {
                    Picker("Crop Type", selection: $type) {
                        ForEach(CropType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    TextField("Crop Name", text: $name)
                    Toggle("Currently Active", isOn: $isActive)
                }
                
                // Dynamic Layout Section
                dynamicFieldsForType(type)
                
                // Save Button
                Section {
                    Button("Save Crop") {
                        saveCrop()
                    }
                }
            }
            .navigationTitle("Add New Crop")
        }
    }
    
    // MARK: - Dynamic Fields for Crop Type
    @ViewBuilder
    private func dynamicFieldsForType(_ type: CropType) -> some View {
        switch type {
        case .greenhouse, .highTunnels, .outdoorBeds:
            greenhouseLayoutFields
        case .treeCrops:
            treeCropFields
        case .seeds:
            seedFields
        }
    }
    
    // Greenhouse/High Tunnels/Outdoor Beds Layout
    private var greenhouseLayoutFields: some View {
        Section(header: Text("Greenhouse Layout")) {
            Stepper("Number of Sections: \(numberOfSections)", value: $numberOfSections, in: 1...10)
            Stepper("Beds Per Section: \(bedsPerSection)", value: $bedsPerSection, in: 1...20)
            
            HStack {
                        Text("Section Length (ft):")
                        TextField("Enter length", value: $sectionLength, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Section Width (ft):")
                        TextField("Enter width", value: $sectionWidth, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
        }
    }
    
    // Tree Crop Fields
    private var treeCropFields: some View {
        Section(header: Text("Tree Crop Details")) {
            TextField("Tree Variety", text: $treeVariety)
            Stepper("Number of Trees: \(numberOfTrees)", value: $numberOfTrees, in: 1...100)
        }
    }
    
    // Seed Fields
    private var seedFields: some View {
        Section(header: Text("Seed Details")) {
            TextField("Seed Variety", text: $seedVariety)
            
            HStack {
                Text("Number of Seeds:")
                TextField("Enter number", text: $numberOfSeedsText)
                    .keyboardType(.numberPad)
                    .onChange(of: numberOfSeedsText) { newValue in
                        if let number = Int(newValue), number > 0 {
                            numberOfSeeds = number
                        } else {
                            numberOfSeedsText = ""
                        }
                    }
            }

            DatePicker("Start Date", selection: $seedStartDate, displayedComponents: .date)

            TextField("Location (e.g., Greenhouse A)", text: $seedLocation)

            HStack {
                Text("Pot Size (inches):")
                TextField("Enter size", text: $potSizeText)
                    .keyboardType(.decimalPad)
                    .onChange(of: potSizeText) { newValue in
                        if let size = Double(newValue), size > 0 {
                            potSize = size
                        } else {
                            potSizeText = ""
                        }
                    }
            }

            TextField("Soil Used", text: $soilUsed)
        }
    }
    
    // MARK: - Save Crop Function
    private func saveCrop() {
        // Validate required fields
        guard !name.isEmpty else {
            print("Crop name is required.")
            return
        }
        
        // Handle sections and beds only if relevant (greenhouse, outdoor beds, high tunnels)
        let sections = type == .greenhouse || type == .highTunnels || type == .outdoorBeds
            ? (0..<numberOfSections).map { sectionIndex in
                (0..<bedsPerSection).map { bedIndex in
                    Bed(
                        id: UUID(),
                        section: sectionIndex + 1,
                        bed: bedIndex + 1,
                        plantCount: 0,
                        state: "Available" // Default state for new beds
                    )
                }
            }
            : []

        // Flatten sections for bed-based crops
        let beds = sections.flatMap { $0 }

        // Create a new crop with relevant fields
        let newCrop = Crop()

        // Append the new crop to the list
        crops.append(newCrop)

        // Debug output
        print("New crop created: \(newCrop)")

        // Dismiss the view
        dismissView()
    }
    
    
    
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}
*/

