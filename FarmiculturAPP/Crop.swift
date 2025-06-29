//
//  Crop.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import Foundation
import SwiftUI


// MARK: - Local Models

struct Crop: Identifiable, Codable, Hashable {
    var id: String
    var type: CropType
    var name: String
    var isActive: Bool
    var sections: [[Bed]]
    var beds: [Bed]
    var sectionLength: Double
    var sectionWidth: Double
    var activities: [Activity]
    var expectedHarvestDate: Date
    var seedVariety: String?
    var numberOfSeeds: Int?
    var treeVariety: String?
    var numberOfTrees: Int?
    var observations: [Observation]
    var seedStartDate: Date?
    var seedLocation: String?
    var seedsPlanted: Int
    var potSize: String?
    var soilUsed: String?
    var tasks: [CropTask] = []
    
    var isHarvestable: Bool {
        return Date() >= expectedHarvestDate
    }
}

enum CropType: String, Codable, CaseIterable {
    case greenhouse = "greenhouse"
    case seeds = "seeds"
    case treeCrops = "treeCrops"
    case outdoorBeds = "outdoorBeds"
    case highTunnels = "highTunnels"
}

struct Bed: Identifiable, Codable, Hashable {
    var id: UUID
    var section: Int
    var bed: Int
    var plantCount: Int
    var state: BedState
    var varieties: [PlantVariety] = []
    
    var totalPlants: Int {
        return varieties.reduce(0) { $0 + $1.count }
    }
    
    mutating func harvest(amount: Int) -> Int {
        guard state == .harvesting || (state == .growing && totalPlants > 0) else {
            return 0
        }
        
        var remainingToHarvest = amount
        var totalHarvested = 0
        
        for i in varieties.indices {
            if remainingToHarvest <= 0 { break }
            let harvested = varieties[i].harvest(amount: remainingToHarvest)
            totalHarvested += harvested
            remainingToHarvest -= harvested
        }
        
        // Update bed state if no plants remain
        if totalPlants == 0 && state == .harvesting {
            state = .dirty
        }
        
        return totalHarvested
    }
}

enum BedState: String, Codable, CaseIterable {
    case dirty = "dirty"
    case clean = "clean"
    case ready = "ready"
    case growing = "growing"
    case harvesting = "harvesting"
    
    var displayName: String {
        switch self {
        case .dirty: return "Dirty"
        case .clean: return "Clean"
        case .ready: return "Ready"
        case .growing: return "Growing"
        case .harvesting: return "Harvesting"
        }
    }
}

struct PlantVariety: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var count: Int
    
    mutating func harvest(amount: Int) -> Int {
        let actualHarvest = min(amount, count)
        count -= actualHarvest
        return actualHarvest
    }
}

struct Activity: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var activityDescription: String?
    var isCompleted: Bool
    var date: Date
}

struct Observation: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var text: String
}

// MARK: - Core Data Models for Firebase

struct FirebaseTask: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Firebase document ID
    var title: String // Was 'name' in Activity
    var descriptionText: String? // Optional for more details
    var isCompleted: Bool = false
    var creationTimestamp: Date = Date()
    var dueDate: Date?
    var assignedToUserId: String? // Links to AppUser.id
    var relatedCropAreaId: String? // Links to FirebaseCropArea.id
    var relatedSectionId: String? // Links to FirebaseSection.id
    var relatedBedId: String? // Links to FirebaseBed.id
    var priority: String? // e.g., "high", "medium", "low"

    enum CodingKeys: String, CodingKey {
        case id, title, descriptionText, isCompleted, creationTimestamp, dueDate,
             assignedToUserId, relatedCropAreaId, relatedSectionId, relatedBedId, priority
    }
}

struct FirebaseObservation: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Firebase document ID
    var date: Date
    var text: String
    var userId: String? // Optional: to track who made the observation, links to AppUser.id

    enum CodingKeys: String, CodingKey {
        case id, date, text, userId
    }
}

struct FirebaseCropArea: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Firebase document ID
    var name: String
    var creationTimestamp: Date = Date()
    var cropType: FirebaseCropType // Enum, was 'type'
    var status: String // "active", "inactive" (was isActive: Bool)
    
    // These fields replace 'sectionLength' and 'sectionWidth' for overall area planning
    var defaultNumberOfSections: Int?
    var defaultBedsPerSection: Int?
    var dimensions: String? // e.g., "50ft x 100ft" for the whole area
    
    var expectedHarvestDate: Date? // Kept from your model
    
    // Specific info based on cropType, grouped for clarity
    var seedInfo: SeedBatchInfo?
    var treeCropInfo: TreeCropInfo?
    
    var observations: [FirebaseObservation] = [] // Can be an array of sub-objects or IDs to a separate collection
    
    // Denormalized stats (updated by Cloud Functions or transactions for efficiency)
    var stats: CropAreaStats?
    
    // Removed: sections: [[Bed]], beds: [[Bed]]?, activities: [Activity]
    // These are now separate collections linked by IDs.
    // Removed: sectionLength, sectionWidth (replaced by 'dimensions' and section-specific dimensions)
    // Removed: seedVariety, numberOfSeeds, treeVariety, numberOfTrees, seedStartDate, seedLocation, seedsPlanted, potSize, soilUsed
    // These are now part of seedInfo or treeCropInfo.

    enum CodingKeys: String, CodingKey {
        case id, name, creationTimestamp, cropType, status,
             defaultNumberOfSections, defaultBedsPerSection, dimensions,
             expectedHarvestDate, seedInfo, treeCropInfo, observations, stats
    }

    // Computed property similar to your 'isHarvestable'
    var isPotentiallyHarvestable: Bool {
        guard let harvestDate = expectedHarvestDate else { return false }
        return Date() >= harvestDate
    }
}

struct SeedBatchInfo: Codable, Hashable {
    var seedVariety: String?
    var numberOfSeedsSown: Int? // Was numberOfSeeds. 'seedsPlanted' from old Crop model seems redundant.
    var seedStartDate: Date?
    var seedLocation: String?
    var potSize: String?
    var soilUsed: String?
}

struct TreeCropInfo: Codable, Hashable {
    var treeVariety: String?
    var numberOfTrees: Int?
}

struct CropAreaStats: Codable, Hashable {
    var totalBeds: Int = 0
    var activeBedsCount: Int = 0 // Sum of beds with status other than 'dirty' or 'clean' (inactive)
    var growingBedsCount: Int = 0
    var readyBedsCount: Int = 0
    var harvestingBedsCount: Int = 0
    var totalPlantsGrowing: Int = 0 // Sum of currentNumberOfPlants for beds in 'growing' or 'harvesting' status
}

struct FirebaseSection: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Firebase document ID
    var cropAreaId: String // Foreign key to FirebaseCropArea.id
    var sectionNumber: String // e.g., "A", "1", "North Wing"
    var name: String? // Optional descriptive name for the section
    var dimensions: String? // e.g., "10ft x 20ft" (can be derived from old sectionLength/Width if they applied per section)
    
    var stats: SectionStats? // Denormalized stats for this specific section
    
    enum CodingKeys: String, CodingKey {
        case id, cropAreaId, sectionNumber, name, dimensions, stats
    }
}

struct SectionStats: Codable, Hashable {
    var totalBeds: Int = 0 // Number of beds physically in this section
    var growingBedsCount: Int = 0
    var readyBedsCount: Int = 0
    var totalPlantsGrowing: Int = 0
}

struct FirebasePlantVariety: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Could be an ID from a master varieties list or just unique within the bed
    var name: String
    var count: Int // Number of this variety in the bed
    // Add other variety-specific details if not using a master list (e.g., plantingDate for this variety in this bed)

    mutating func harvest(amount: Int) -> Int {
        let actualHarvest = min(amount, count)
        count -= actualHarvest
        return actualHarvest
    }
}
enum FirebaseBedState: String, Codable, CaseIterable, Hashable { // Added Hashable
    case dirty // "dirty"
    case clean // "clean"
    case ready // "ready"
    case growing // "growing"
    // case harvestReady // Your old 'harvestReady'. Consider if 'growing' with mature plants covers this,
                       // or if 'harvesting' implies it's ready. Often, 'growing' transitions to 'harvesting'.
    case harvesting // "harvesting"
    
    var color: Color {
        switch self {
        case .dirty: return .brown
        case .clean: return .gray
        case .ready: return .blue
        case .growing: return .green
        // case .harvestReady: return .orange
        case .harvesting: return .red
        }
    }
    
    var displayName: String { // For UI, matches your old 'description' but uses rawValue for simplicity
        switch self {
        case .dirty: return "Dirty"
        case .clean: return "Clean"
        case .ready: return "Ready"
        case .growing: return "Growing"
        // case .harvestReady: return "Harvest Ready"
        case .harvesting: return "Harvesting"
        }
    }
}

struct FirebaseBed: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // Firebase document ID
    var sectionId: String // Foreign key to FirebaseSection.id
    var cropAreaId: String // Denormalized foreign key to FirebaseCropArea.id for easier querying
    
    var bedNumber: String // e.g., "A1", "1" (replaces old section/bed Ints for display)
    var dateStamp: Date = Date() // Timestamp of last status change or planting
    var status: FirebaseBedState // Enum (was 'state')
    
    var varieties: [FirebasePlantVariety] = [] // Array of plant varieties in this bed
    // var plantCount: Int // This was in your old Bed struct. 'currentNumberOfPlants' computed property replaces its intent.
                            // If 'plantCount' was a target capacity, consider a 'targetPlantCapacity' field.
    
    // For harvest reporting by workers
    var harvestInput: BedHarvestInput?
    var notes: String? // General notes for this specific bed

    var currentNumberOfPlants: Int { // Was 'totalPlants'
        varieties.reduce(0) { $0 + $1.count }
    }
    
    mutating func performHarvest(amount: Int) -> Int { // Renamed from 'harvest' to avoid conflict if FirebaseBed itself has a harvest method
        // This logic will likely be expanded in a ViewModel or service layer,
        // especially when considering moving data to 'pastBeds' upon completion of harvest.
        // For now, it mirrors your existing harvest logic for varieties.
        guard status == .harvesting || (status == .growing && currentNumberOfPlants > 0) /* Allow harvesting from growing if needed */ else {
            return 0 // Or throw an error, or handle appropriately in UI
        }
        
        var remainingToHarvest = amount
        var totalHarvested = 0
        
        for i in varieties.indices { // Use 'i' for clarity if 'index' is used elsewhere
            if remainingToHarvest <= 0 { break }
            let harvested = varieties[i].harvest(amount: remainingToHarvest)
            totalHarvested += harvested
            remainingToHarvest -= harvested
        }
        
        // Update bed status based on remaining plants - this part needs careful thought
        // in the context of the full workflow (e.g., when does it become 'dirty' vs 'clean' after harvest?)
        if currentNumberOfPlants == 0 && status == .harvesting {
            // status = .dirty // Or .clean, depending on the farm's process.
                           // This status change might also be triggered by a user action "Close Bed".
        }
        
        return totalHarvested
    }

    enum CodingKeys: String, CodingKey {
        case id, sectionId, cropAreaId, bedNumber, dateStamp, status, varieties, harvestInput, notes
    }
}

struct BedHarvestInput: Codable, Hashable { // For workers to input harvest data
    var quantity: Double?
    var unit: String? // e.g., "kg", "lbs", "bunches", "pieces"
    var notes: String? // e.g., "Excellent quality, few blemishes"
    var harvestTimestamp: Date?
}

enum FirebaseCropType: String, Codable, CaseIterable, Hashable { // Added Hashable
    case greenhouse // "greenhouse"
    case seedBatch // "seedBatch" (was "seeds" with rawValue "Seed Batch")
    case treeCrop // "treeCrop" (was "treeCrops" with rawValue "Tree Crops")
    case outdoorBed // "outdoorBed" (was "outdoorBeds" with rawValue "Outdoor Beds")
    case highTunnel // "highTunnel" (was "highTunnels" with rawValue "High Tunnels")
    
    var displayName: String { // For UI presentation
        switch self {
        case .greenhouse: return "Greenhouse"
        case .seedBatch: return "Seed Batch"
        case .treeCrop: return "Tree Crop"
        case .outdoorBed: return "Outdoor Bed"
        case .highTunnel: return "High Tunnel"
        }
    }
}

// MARK: - User Model (Example for Firebase)
struct AppUser: Identifiable, Codable, Hashable {
    var id: String // Firebase Auth UID
    var email: String?
    var name: String?
    var role: String // e.g., "worker", "manager", "admin"
    // Add other user-specific fields as needed
}
