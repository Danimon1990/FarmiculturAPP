//
//  MainAppView.swift
//  FarmiculturAPP
//
//  Main app interface with tab navigation
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var selectedTab = 0
    @State private var showingFirstTimeSetup = false
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading your farm...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if farmService.currentFarmId == nil {
                FirstTimeSetupView()
            } else {
                TabView(selection: $selectedTab) {
                    EnhancedAreasView()
                        .tabItem {
                            Label("Areas", systemImage: "map.fill")
                        }
                        .tag(0)

                    HarvestDashboardView()
                        .tabItem {
                            Label("Harvest", systemImage: "basket.fill")
                        }
                        .tag(1)

                    TasksView()
                        .tabItem {
                            Label("Tasks", systemImage: "checklist")
                        }
                        .tag(2)

                    ChatView()
                        .tabItem {
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .tag(3)
                }
            }
        }
        .onAppear {
            checkForExistingFarm()
        }
    }
    
    func checkForExistingFarm() {
        // Check Firebase for existing farms
        
        // If no local farm, check Firebase
        Task {
            await farmService.loadExistingFarm()
            isLoading = false
        }
    }
}

// MARK: - First Time Setup

struct FirstTimeSetupView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var farmName = ""
    @State private var location = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Welcome! Let's set up your farm")) {
                    TextField("Farm Name", text: $farmName)
                    TextField("Location (optional)", text: $location)
                }
                
                Section {
                    Button(action: createFarm) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Text("Create Farm")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(farmName.isEmpty || isCreating)
                }
            }
            .navigationTitle("Setup")
        }
    }
    
    func createFarm() {
        isCreating = true
        Task {
            let farm = Farm(
                name: farmName,
                owner: farmService.currentFarmUser?.displayName,
                location: location.isEmpty ? nil : location
            )
            
            do {
                try await farmService.createFarm(farm)
            } catch {
                print("Failed to create farm: \(error)")
            }
            
            isCreating = false
        }
    }
}

// MARK: - Crop Areas View

struct CropAreasView: View {
    @EnvironmentObject var farmService: FarmDataService
    @State private var cropAreas: [CropArea] = []
    @State private var showingAddArea = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if cropAreas.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "building.2")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Crop Areas Yet")
                            .font(.title2)
                        Text("Create your first growing area")
                            .foregroundColor(.secondary)
                        Button(action: { showingAddArea = true }) {
                            Label("Add Crop Area", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(cropAreas) { area in
                            NavigationLink(destination: AreaDetailView(area: area)) {
                                CropAreaRowView(area: area)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Crop Areas")
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
            .onAppear {
                loadCropAreas()
            }
        }
    }
    
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

struct CropAreaRowView: View {
    let area: CropArea
    
    var body: some View {
        HStack {
            Image(systemName: area.type.icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(area.name)
                    .font(.headline)
                Text(area.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Crop Area

struct AddCropAreaView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Environment(\.dismiss) var dismiss
    @Binding var cropAreas: [CropArea]
    
    @State private var name = ""
    @State private var selectedType: CropAreaType = .greenhouse
    @State private var dimensions = ""
    @State private var notes = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Area Information")) {
                    TextField("Name (e.g., Greenhouse 1)", text: $name)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(CropAreaType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    
                    TextField("Dimensions (optional)", text: $dimensions)
                        .keyboardType(.default)
                }
                
                Section(header: Text("Notes (optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: saveArea) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create Area")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .navigationTitle("New Crop Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func saveArea() {
        guard let farmId = farmService.currentFarmId else { return }
        isSaving = true
        
        let area = CropArea(
            farmId: farmId,
            name: name,
            type: selectedType,
            dimensions: dimensions.isEmpty ? nil : dimensions,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                try await farmService.createCropArea(area)
                cropAreas.append(area)
                dismiss()
            } catch {
                print("Failed to save area: \(error)")
            }
            isSaving = false
        }
    }
}

// MARK: - Preview

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(FarmDataService.shared)
    }
}

