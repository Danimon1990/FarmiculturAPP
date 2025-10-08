//
//  FarmDataService.swift
//  FarmiculturAPP
//
//  Firebase service for new data structure
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class FarmDataService: ObservableObject {
    static let shared = FarmDataService()
    
    @Published var currentUser: User?
    @Published var currentFarmUser: FarmUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // Current farm context
    @Published var currentFarmId: String?
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                if let user = user {
                    await self?.loadCurrentFarmUser(userId: user.uid)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            await loadCurrentFarmUser(userId: result.user.uid)
            
            // Load existing farm data
            await loadExistingFarm()
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            
            // Create farm user profile
            let farmUser = FarmUser(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                role: .admin // First user is admin
            )
            try await saveFarmUser(farmUser)
            currentFarmUser = farmUser
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            currentFarmUser = nil
            currentFarmId = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Farm User Management
    
    func loadCurrentFarmUser(userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let data = doc.data() {
                currentFarmUser = try Firestore.Decoder().decode(FarmUser.self, from: data)
                
                // Try to load existing farm for this user
                await loadExistingFarm()
            }
        } catch {
            print("Failed to load farm user: \(error)")
        }
    }
    
    func loadExistingFarm() async {
        do {
            let farms = try await loadFarms()
            print("🔍 Found \(farms.count) farms in Firebase")
            
            if let firstFarm = farms.first {
                currentFarmId = firstFarm.id
                LocalDataManager.shared.saveCurrentFarmId(firstFarm.id)
                LocalDataManager.shared.saveFarm(firstFarm)
                print("✅ Loaded existing farm: \(firstFarm.name) (ID: \(firstFarm.id))")
            } else {
                print("❌ No farms found in Firebase")
            }
        } catch {
            print("❌ Error loading farms: \(error)")
        }
    }
    
    func saveFarmUser(_ user: FarmUser) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection("users").document(user.id).setData(data)
    }
    
    // MARK: - Farm Operations
    
    func createFarm(_ farm: Farm) async throws {
        let data = try Firestore.Encoder().encode(farm)
        try await db.collection("farms").document(farm.id).setData(data)
        currentFarmId = farm.id
    }
    
    func loadFarms() async throws -> [Farm] {
        let snapshot = try await db.collection("farms").getDocuments()
        return try snapshot.documents.compactMap { doc in
            try Firestore.Decoder().decode(Farm.self, from: doc.data())
        }
    }
    
    func hasExistingFarms() async -> Bool {
        do {
            let farms = try await loadFarms()
            return !farms.isEmpty
        } catch {
            print("Error checking for existing farms: \(error)")
            return false
        }
    }
    
    func loadFarm(farmId: String) async throws -> Farm? {
        let doc = try await db.collection("farms").document(farmId).getDocument()
        guard let data = doc.data() else { return nil }
        return try Firestore.Decoder().decode(Farm.self, from: data)
    }
    
    // MARK: - Crop Area Operations
    
    func createCropArea(_ area: CropArea) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(area)
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(area.id).setData(data)
    }
    
    func loadCropAreas(farmId: String) async throws -> [CropArea] {
        let snapshot = try await db.collection("farms").document(farmId)
            .collection("cropAreas").getDocuments()
        return try snapshot.documents.compactMap { doc in
            try Firestore.Decoder().decode(CropArea.self, from: doc.data())
        }
    }
    
    func updateCropArea(_ area: CropArea) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(area)
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(area.id).setData(data, merge: true)
    }
    
    func deleteCropArea(_ areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId).delete()
    }
    
    // MARK: - Section Operations
    
    func createSection(_ section: CropSection, in areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(section)
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(section.id).setData(data)
    }
    
    func loadSections(farmId: String, areaId: String) async throws -> [CropSection] {
        let snapshot = try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").getDocuments()
        return try snapshot.documents.compactMap { doc in
            try Firestore.Decoder().decode(CropSection.self, from: doc.data())
        }
    }
    
    func updateSection(_ section: CropSection, in areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(section)
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(section.id).setData(data, merge: true)
    }
    
    // MARK: - Bed Operations (Primary Working Unit)
    
    func createBed(_ bed: Bed, in sectionId: String, areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(bed)
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(sectionId)
            .collection("beds").document(bed.id).setData(data)
    }
    
    func loadBeds(farmId: String, areaId: String, sectionId: String) async throws -> [Bed] {
        let snapshot = try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(sectionId)
            .collection("beds").getDocuments()
        
        let beds = try snapshot.documents.compactMap { doc -> Bed? in
            var data = doc.data()
            print("🔄 Loading bed from Firestore:")
            print("   - Document ID: \(doc.documentID)")
            if let bedNumber = data["bedNumber"] as? String {
                print("   - Bed number: \(bedNumber)")
            }
            if let varieties = data["varieties"] as? [[String: Any]] {
                print("   - Varieties in Firestore: \(varieties.count)")
                print("   - Varieties data: \(varieties)")
            } else {
                print("   - ⚠️ No varieties found in Firestore data")
                // Migration fallback: default to empty varieties for older docs
                data["varieties"] = []
            }
            if let totalPlantCount = data["totalPlantCount"] {
                print("   - Total plant count in Firestore: \(totalPlantCount)")
            }
            
            // Ensure statusHistory exists for decoder
            if data["statusHistory"] == nil { data["statusHistory"] = [] }
            // Ensure required identity fields exist
            if data["id"] == nil { data["id"] = doc.documentID }
            if data["createdDate"] == nil { data["createdDate"] = Timestamp(date: Date()) }
            
            let bed = try Firestore.Decoder().decode(Bed.self, from: data)
            print("   - After decoding: \(bed.varieties.count) varieties, \(bed.totalPlantCount) plants")
            return bed
        }
        
        return beds
    }
    
    func loadAllBeds(farmId: String, areaId: String) async throws -> [Bed] {
        // Load all beds across all sections in an area
        let sections = try await loadSections(farmId: farmId, areaId: areaId)
        var allBeds: [Bed] = []
        
        for section in sections {
            let beds = try await loadBeds(farmId: farmId, areaId: areaId, sectionId: section.id)
            allBeds.append(contentsOf: beds)
        }
        
        return allBeds
    }
    
    func updateBed(_ bed: Bed, in sectionId: String, areaId: String) async throws {
        guard let farmId = currentFarmId else { 
            print("❌ No farm selected for bed update")
            throw FarmDataError.noFarmSelected 
        }
        
        print("🔄 FarmDataService: Updating bed \(bed.bedNumber) in Firebase")
        print("🔄 Path: farms/\(farmId)/cropAreas/\(areaId)/sections/\(sectionId)/beds/\(bed.id)")
        print("🔄 Bed varieties before encoding: \(bed.varieties.count)")
        print("🔄 Bed totalPlantCount before encoding: \(bed.totalPlantCount)")
        
        let data = try Firestore.Encoder().encode(bed)
        print("🔄 Encoded bed data keys: \(data.keys.joined(separator: ", "))")
        print("🔄 Full encoded data: \(data)")
        
        if let varieties = data["varieties"] as? [[String: Any]] {
            print("🔄 Encoded varieties count: \(varieties.count)")
            print("🔄 Encoded varieties: \(varieties)")
        } else {
            print("⚠️ No varieties in encoded data!")
        }
        if let totalPlantCount = data["totalPlantCount"] {
            print("🔄 Encoded totalPlantCount: \(totalPlantCount)")
        } else {
            print("⚠️ No totalPlantCount in encoded data!")
        }
        
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(sectionId)
            .collection("beds").document(bed.id).setData(data, merge: false)
            
        print("✅ FarmDataService: Bed successfully saved to Firebase")
    }
    
    func deleteBed(_ bedId: String, in sectionId: String, areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(sectionId)
            .collection("beds").document(bedId).delete()
    }
    
    func deleteBed(bedId: String, sectionId: String, areaId: String) async throws {
        try await deleteBed(bedId, in: sectionId, areaId: areaId)
    }
    
    func deleteSection(sectionId: String, areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId)
            .collection("sections").document(sectionId).delete()
    }
    
    func deleteCropArea(areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        try await db.collection("farms").document(farmId)
            .collection("cropAreas").document(areaId).delete()
    }
    
    // MARK: - Harvest Report Operations
    
    func addHarvestReport(_ report: HarvestReport, to bed: Bed, sectionId: String, areaId: String) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        
        // Add report to bed
        var updatedBed = bed
        updatedBed.addHarvestReport(report)
        
        // Update bed in Firestore
        try await updateBed(updatedBed, in: sectionId, areaId: areaId)
        
        // Also store harvest report separately for easier querying
        let data = try Firestore.Encoder().encode(report)
        try await db.collection("farms").document(farmId)
            .collection("harvestReports").document(report.id).setData(data)
    }
    
    func loadHarvestReports(farmId: String, startDate: Date? = nil, endDate: Date? = nil) async throws -> [HarvestReport] {
        var query: Query = db.collection("farms").document(farmId)
            .collection("harvestReports")
            .order(by: "date", descending: true)
        
        if let start = startDate {
            query = query.whereField("date", isGreaterThanOrEqualTo: start)
        }
        
        if let end = endDate {
            query = query.whereField("date", isLessThanOrEqualTo: end)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { doc in
            try Firestore.Decoder().decode(HarvestReport.self, from: doc.data())
        }
    }
    
    // MARK: - Completed Beds (Archive)
    
    func archiveBed(_ bed: Bed, sectionId: String, areaId: String, finalNotes: String? = nil) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        guard let userId = currentUser?.uid else { throw FarmDataError.notAuthenticated }
        
        // Create completed bed record
        let completedBed = CompletedBed(
            from: bed,
            archivedBy: currentFarmUser?.displayName ?? userId,
            finalNotes: finalNotes
        )
        
        // Save to archive
        let data = try Firestore.Encoder().encode(completedBed)
        try await db.collection("farms").document(farmId)
            .collection("completedBeds").document(completedBed.id).setData(data)
        
        // Delete original bed
        try await deleteBed(bed.id, in: sectionId, areaId: areaId)
    }
    
    func loadCompletedBeds(farmId: String, year: Int? = nil) async throws -> [CompletedBed] {
        var query: Query = db.collection("farms").document(farmId)
            .collection("completedBeds")
            .order(by: "endDate", descending: true)
        
        if let year = year {
            query = query.whereField("seasonYear", isEqualTo: year)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { doc in
            try Firestore.Decoder().decode(CompletedBed.self, from: doc.data())
        }
    }
    
    // MARK: - Task Operations
    
    func createTask(_ task: BedTask) async throws {
        guard let farmId = currentFarmId else {
            print("❌ No farm selected for task creation")
            throw FarmDataError.noFarmSelected
        }

        print("🔄 Creating task: \(task.title)")
        print("   - Farm ID: \(farmId)")
        print("   - Task ID: \(task.id)")
        print("   - Priority: \(task.priority.rawValue)")
        print("   - Crop Area ID: \(task.cropAreaId ?? "none")")

        let data = try Firestore.Encoder().encode(task)
        print("   - Encoded data keys: \(data.keys.joined(separator: ", "))")

        try await db.collection("farms").document(farmId)
            .collection("tasks").document(task.id).setData(data)

        print("✅ Task created successfully in Firebase")
    }
    
    func loadTasks(farmId: String, bedId: String? = nil, isCompleted: Bool? = nil) async throws -> [BedTask] {
        print("🔄 Loading tasks for farm: \(farmId)")

        var query: Query = db.collection("farms").document(farmId)
            .collection("tasks")
            .order(by: "createdDate", descending: true)

        if let bedId = bedId {
            query = query.whereField("bedId", isEqualTo: bedId)
        }

        if let completed = isCompleted {
            query = query.whereField("isCompleted", isEqualTo: completed)
        }

        let snapshot = try await query.getDocuments()
        print("✅ Found \(snapshot.documents.count) task documents")

        let tasks = try snapshot.documents.compactMap { doc -> BedTask? in
            print("   - Task document ID: \(doc.documentID)")
            return try Firestore.Decoder().decode(BedTask.self, from: doc.data())
        }

        print("✅ Decoded \(tasks.count) tasks")
        return tasks
    }
    
    func updateTask(_ task: BedTask) async throws {
        guard let farmId = currentFarmId else { throw FarmDataError.noFarmSelected }
        let data = try Firestore.Encoder().encode(task)
        try await db.collection("farms").document(farmId)
            .collection("tasks").document(task.id).setData(data, merge: true)
    }
}

// MARK: - Errors

enum FarmDataError: LocalizedError {
    case noFarmSelected
    case notAuthenticated
    case invalidData
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noFarmSelected: return "No farm selected. Please select a farm first."
        case .notAuthenticated: return "User not authenticated."
        case .invalidData: return "Invalid data format."
        case .networkError: return "Network error occurred."
        }
    }
}

