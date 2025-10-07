//
//  Models.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno
//  Clean data structure - Phase 1
//

import Foundation
import SwiftUI

// MARK: - Farm Hierarchy

/// Top-level farm organization
struct Farm: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var owner: String?
    var location: String?
    var createdDate: Date = Date()
    var notes: String?
}

/// Crop growing area (Greenhouse, High Tunnel, Outdoor area, etc.)
struct CropArea: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var farmId: String
    var name: String // e.g., "Greenhouse 1", "High Tunnel A"
    var type: CropAreaType
    var createdDate: Date = Date()
    var dimensions: String? // e.g., "50ft x 100ft"
    var notes: String?
}

enum CropAreaType: String, Codable, CaseIterable, Hashable {
    case greenhouse = "greenhouse"
    case highTunnel = "highTunnel"
    case outdoorBeds = "outdoorBeds"
    case seedHouse = "seedHouse"
    case treeCrops = "treeCrops"
    
    var displayName: String {
        switch self {
        case .greenhouse: return "Greenhouse"
        case .highTunnel: return "High Tunnel"
        case .outdoorBeds: return "Outdoor Beds"
        case .seedHouse: return "Seed House"
        case .treeCrops: return "Tree Crops"
        }
    }
    
    var icon: String {
        switch self {
        case .greenhouse: return "leaf.fill"
        case .highTunnel: return "building.2.fill"
        case .outdoorBeds: return "square.grid.3x3.fill"
        case .seedHouse: return "ladybug.fill"
        case .treeCrops: return "tree.fill"
        }
    }
}

/// Section within a crop area
struct CropSection: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var cropAreaId: String
    var name: String // e.g., "Section A", "North Wing"
    var sectionNumber: String? // e.g., "A", "1", "N"
    var createdDate: Date = Date()
    var dimensions: String?
    var notes: String?
}

// MARK: - Bed (Primary Working Unit)

/// The main unit of work - where crops are grown
struct Bed: Identifiable, Codable, Hashable {
    // Identity & Location
    var id: String = UUID().uuidString
    var sectionId: String
    var cropAreaId: String // Denormalized for easier querying
    var bedNumber: String // e.g., "A1", "B3", "North-12"
    var createdDate: Date = Date()
    
    // Current Status
    var status: BedStatus
    var statusHistory: [StatusChange] = []
    
    // Planting Information
    var startMethod: StartMethod?
    var datePlanted: Date?
    var varieties: [PlantVariety] = []
    
    // Harvest Timing
    var expectedHarvestStart: Date?
    var expectedHarvestEnd: Date?
    
    // Tracking
    var harvestReports: [HarvestReport] = []
    var notes: String?
    var currentCropName: String? // e.g., "Cherry Tomatoes Spring 2025"
    
    // Computed Properties
    var totalPlantCount: Int {
        varieties.reduce(0) { $0 + $1.count }
    }
    
    var isMultipleHarvest: Bool {
        varieties.contains { $0.continuousHarvest }
    }
    
    var totalHarvested: Double {
        harvestReports.reduce(0) { $0 + $1.quantity }
    }
    
    var isActivelyHarvesting: Bool {
        guard let start = expectedHarvestStart else { return false }
        let now = Date()
        if let end = expectedHarvestEnd {
            return now >= start && now <= end && status == .harvesting
        }
        return now >= start && status == .harvesting
    }
    
    var lastStatusChange: StatusChange? {
        statusHistory.last
    }
    
    var daysSincePlanted: Int? {
        guard let planted = datePlanted else { return nil }
        return Calendar.current.dateComponents([.day], from: planted, to: Date()).day
    }
    
    
    mutating func addStatusChange(to newStatus: BedStatus, by user: String? = nil, notes: String? = nil) {
        let change = StatusChange(
            fromStatus: status,
            toStatus: newStatus,
            date: Date(),
            changedBy: user,
            notes: notes
        )
        statusHistory.append(change)
        status = newStatus
    }
    
    mutating func addHarvestReport(_ report: HarvestReport) {
        harvestReports.append(report)
    }
}

/// Bed lifecycle status
enum BedStatus: String, Codable, CaseIterable, Hashable {
    case dirty = "dirty"           // Needs cleaning
    case clean = "clean"           // Cleaned, ready for prep
    case prepared = "prepared"     // Soil prepped, ready for planting
    case planted = "planted"       // Seeds/transplants just added
    case growing = "growing"       // Active growth phase
    case harvesting = "harvesting" // Currently being harvested
    case completed = "completed"   // Harvest finished, ready to archive
    
    var displayName: String {
        switch self {
        case .dirty: return "Dirty"
        case .clean: return "Clean"
        case .prepared: return "Prepared"
        case .planted: return "Planted"
        case .growing: return "Growing"
        case .harvesting: return "Harvesting"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .dirty: return .brown
        case .clean: return .gray
        case .prepared: return .blue
        case .planted: return .cyan
        case .growing: return .green
        case .harvesting: return .orange
        case .completed: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .dirty: return "xmark.circle"
        case .clean: return "sparkles"
        case .prepared: return "checkmark.circle"
        case .planted: return "seedling"
        case .growing: return "leaf.fill"
        case .harvesting: return "basket.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
}

/// Track status changes over time
struct StatusChange: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var fromStatus: BedStatus?
    var toStatus: BedStatus
    var date: Date
    var changedBy: String?
    var notes: String?
}

/// How the bed was started
enum StartMethod: String, Codable, CaseIterable, Hashable {
    case directSeed = "directSeed"       // Seeded directly in bed
    case transplanted = "transplanted"   // Started in seedhouse, moved to bed
    
    var displayName: String {
        switch self {
        case .directSeed: return "Direct Seed"
        case .transplanted: return "Transplanted"
        }
    }
    
    var icon: String {
        switch self {
        case .directSeed: return "leaf.circle"
        case .transplanted: return "arrow.right.circle"
        }
    }
}

// MARK: - Plant Variety

/// Plant variety information within a bed
struct PlantVariety: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String = "" // Default empty string for optional names
    var count: Int = 0
    var daysToMaturity: Int? // Expected days from planting to harvest
    var continuousHarvest: Bool = false // Single harvest vs continuous
    var harvestWindowDays: Int? // How long harvest period lasts (for continuous)
    var notes: String?
    
    // Computed
    var estimatedHarvestDate: Date? {
        guard let days = daysToMaturity else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: Date())
    }
}

// MARK: - Harvest Tracking

/// Worker harvest report
struct HarvestReport: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var bedId: String
    var date: Date = Date()
    var reportedBy: String // Worker name/ID
    var quantity: Double
    var unit: HarvestUnit
    var quality: HarvestQuality?
    var notes: String?
    var varieties: [String] = [] // Which varieties were harvested
    var weight: Double? // Optional additional weight tracking
}

enum HarvestUnit: String, Codable, CaseIterable, Hashable {
    case plants = "plants"
    case kilograms = "kilograms"
    case pounds = "pounds"
    case bunches = "bunches"
    case boxes = "boxes"
    case trays = "trays"
    case pieces = "pieces"
    
    var displayName: String {
        self.rawValue.capitalized
    }
    
    var shortName: String {
        switch self {
        case .plants: return "plants"
        case .kilograms: return "kg"
        case .pounds: return "lbs"
        case .bunches: return "bunches"
        case .boxes: return "boxes"
        case .trays: return "trays"
        case .pieces: return "pcs"
        }
    }
}

enum HarvestQuality: String, Codable, CaseIterable, Hashable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        self.rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "minus.circle"
        case .poor: return "hand.thumbsdown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - Completed Beds (Archive)

/// Archived bed after harvest is complete
struct CompletedBed: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var originalBedId: String
    var bedSnapshot: Bed // Complete snapshot of bed at completion
    
    // Summary Stats
    var seasonYear: Int
    var startDate: Date
    var endDate: Date
    var totalHarvested: Double
    var harvestUnit: HarvestUnit
    var totalReports: Int
    var durationDays: Int
    var avgYieldPerDay: Double
    
    // Additional Info
    var finalNotes: String?
    var archivedBy: String?
    var archivedDate: Date = Date()
    
    init(from bed: Bed, archivedBy: String? = nil, finalNotes: String? = nil) {
        self.originalBedId = bed.id
        self.bedSnapshot = bed
        
        let calendar = Calendar.current
        self.seasonYear = calendar.component(.year, from: bed.datePlanted ?? Date())
        self.startDate = bed.datePlanted ?? bed.createdDate
        self.endDate = Date()
        
        self.totalHarvested = bed.totalHarvested
        self.harvestUnit = bed.harvestReports.first?.unit ?? .plants
        self.totalReports = bed.harvestReports.count
        
        let duration = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        self.durationDays = duration
        self.avgYieldPerDay = duration > 0 ? totalHarvested / Double(duration) : 0
        
        self.finalNotes = finalNotes
        self.archivedBy = archivedBy
    }
}

// MARK: - User Model

/// User/Worker information
struct FarmUser: Identifiable, Codable, Hashable {
    var id: String // Firebase Auth UID
    var email: String?
    var displayName: String
    var role: UserRole
    var createdDate: Date = Date()
    var lastActive: Date?
}

enum UserRole: String, Codable, CaseIterable, Hashable {
    case admin = "admin"
    case manager = "manager"
    case worker = "worker"
    case viewer = "viewer"
    
    var displayName: String {
        self.rawValue.capitalized
    }
}

// MARK: - Tasks & Activities

/// Task associated with a bed or area
struct BedTask: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var bedId: String?
    var sectionId: String?
    var cropAreaId: String?
    var title: String
    var taskDescription: String?
    var dueDate: Date?
    var isCompleted: Bool = false
    var completedDate: Date?
    var assignedTo: String? // User ID
    var createdBy: String?
    var createdDate: Date = Date()
    var priority: TaskPriority = .medium
}

enum TaskPriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        self.rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Helper Extensions

extension Date {
    func daysUntil(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: self, to: date).day ?? 0
    }
    
    func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
}

