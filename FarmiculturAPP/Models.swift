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

    // MCP: Availability Tracking (NEW)
    var availabilityStatus: AvailabilityStatus = .available
    var availableFrom: Date? // When bed becomes free for planting
    var lastCropName: String? // For crop rotation planning
    var soilRestDays: Int? // Days to wait before replanting (optional)

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

/// MCP: Bed availability for planting (NEW)
enum AvailabilityStatus: String, Codable, CaseIterable, Hashable {
    case available = "available"   // Ready to plant now
    case reserved = "reserved"     // Assigned for upcoming planting
    case occupied = "occupied"     // Currently has crops growing

    var displayName: String {
        self.rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .available: return .green
        case .reserved: return .yellow
        case .occupied: return .red
        }
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

    // MCP: Enhanced task tracking (NEW)
    var estimatedHours: Double? // Time estimate
    var actualHours: Double? // Time spent
    var dependencies: [String] = [] // taskIds that must complete first
    var subtasks: [Subtask] = [] // Checklist items
    var activityLog: [TaskActivity] = [] // Comments and updates
    var recurringSchedule: RecurringSchedule? // For weekly/monthly tasks
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

// MARK: - MCP Enhanced Models (NEW)

/// Subtask within a task (checklist item)
struct Subtask: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var description: String
    var isCompleted: Bool = false
    var completedBy: String?
    var completedDate: Date?
}

/// Activity log entry for tasks
struct TaskActivity: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var activityType: TaskActivityType
    var description: String
    var performedBy: String
    var timestamp: Date = Date()
}

enum TaskActivityType: String, Codable, Hashable {
    case created = "created"
    case updated = "updated"
    case completed = "completed"
    case commented = "commented"
    case assigned = "assigned"
    case statusChanged = "statusChanged"
}

/// Recurring schedule for tasks
struct RecurringSchedule: Codable, Hashable {
    var frequency: RecurringFrequency
    var dayOfWeek: DayOfWeek? // For weekly
    var dayOfMonth: Int? // For monthly (1-31)
    var nextOccurrence: Date
}

enum RecurringFrequency: String, Codable, CaseIterable, Hashable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        self.rawValue.capitalized
    }
}

enum DayOfWeek: String, Codable, CaseIterable, Hashable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"

    var displayName: String {
        self.rawValue.capitalized
    }
}

/// Worker profile with performance metrics
struct WorkerProfile: Identifiable, Codable, Hashable {
    var id: String // userId from FarmUser
    var displayName: String
    var skills: [WorkerSkill] = []
    var availability: [DayOfWeek] = []

    // Performance metrics (computed from harvest reports & tasks)
    var totalHarvestsReported: Int = 0
    var totalQuantityHarvested: Double = 0
    var averageQualityRating: Double = 0
    var tasksCompletedCount: Int = 0
    var tasksCreatedCount: Int = 0

    // Tracking
    var metricsLastUpdated: Date?
    var seasonalStats: [String: SeasonalWorkerStats] = [:] // "2025-Spring": {...}
}

struct SeasonalWorkerStats: Codable, Hashable {
    var season: String
    var harvestCount: Int
    var totalQuantity: Double
    var avgQuality: Double
    var tasksCompleted: Int
    var mostHarvestedCrop: String?
}

enum WorkerSkill: String, Codable, CaseIterable, Hashable {
    case planting = "planting"
    case harvesting = "harvesting"
    case soilPreparation = "soilPreparation"
    case transplanting = "transplanting"
    case bedMaintenance = "bedMaintenance"
    case recordKeeping = "recordKeeping"

    var displayName: String {
        switch self {
        case .planting: return "Planting"
        case .harvesting: return "Harvesting"
        case .soilPreparation: return "Soil Preparation"
        case .transplanting: return "Transplanting"
        case .bedMaintenance: return "Bed Maintenance"
        case .recordKeeping: return "Record Keeping"
        }
    }

    var icon: String {
        switch self {
        case .planting: return "leaf.fill"
        case .harvesting: return "basket.fill"
        case .soilPreparation: return "rectangle.stack.fill"
        case .transplanting: return "arrow.right.circle.fill"
        case .bedMaintenance: return "wrench.fill"
        case .recordKeeping: return "doc.text.fill"
        }
    }
}

/// Crop performance analytics
struct CropStats: Identifiable, Codable, Hashable {
    var id: String // cropName slug (e.g., "cherry-tomatoes")
    var cropName: String
    var farmId: String

    // Aggregate performance
    var totalBedsGrown: Int = 0
    var totalBedsCompleted: Int = 0
    var avgYieldPerBed: Double = 0
    var avgYieldUnit: HarvestUnit = .kilograms
    var avgDaysToMaturity: Int = 0
    var avgHarvestWindowDays: Int = 0

    // Quality metrics
    var avgQualityRating: Double = 0 // 1-4 scale
    var successRate: Double = 0 // % beds with good yield

    // Seasonal data
    var harvestsByMonth: [String: Double] = [:] // "Jan": 45.5, "Feb": 32.1
    var bestPlantingMonths: [String] = []
    var bestHarvestMonths: [String] = []

    // Variety breakdown
    var varietyPerformance: [String: VarietyStats] = [:]

    // Updated tracking
    var lastUpdated: Date = Date()
    var dataSourceBeds: [String] = [] // completedBed IDs
}

struct VarietyStats: Codable, Hashable {
    var varietyName: String
    var bedsGrown: Int
    var avgYield: Double
    var avgQuality: Double
    var avgMaturityDays: Int
}

/// Harvest forecast for planning
struct HarvestForecast: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var bedId: String
    var cropName: String
    var varieties: [String] = []

    // Forecast data
    var expectedHarvestStart: Date
    var expectedHarvestEnd: Date? // For continuous harvest
    var estimatedQuantity: Double
    var estimatedUnit: HarvestUnit
    var confidenceLevel: Int = 50 // 0-100%

    // Source of forecast
    var basedOnMaturityDays: Int
    var datePlanted: Date
    var plantCount: Int
    var historicalAvgYield: Double? // From cropStats

    // Status
    var isCurrent: Bool = true // False after harvest starts
    var actualHarvestStarted: Date?
    var createdDate: Date = Date()
    var updatedDate: Date = Date()
}

/// Production planning for seasons
struct ProductionPlan: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var farmId: String
    var season: String // "Spring 2025", "Summer 2025"
    var startDate: Date
    var endDate: Date

    // Goals
    var targetCrops: [CropTarget] = []
    var totalBedsPlanned: Int = 0

    // Execution tracking
    var bedsPlanted: Int = 0
    var planningStatus: PlanningStatus = .draft
    var completionPercentage: Double = 0

    // Scheduling
    var plantingSchedule: [PlantingScheduleEntry] = []
    var rotationPlan: [String: String] = [:] // bedId: nextCropName

    var createdBy: String?
    var createdDate: Date = Date()
    var lastUpdated: Date = Date()
}

struct CropTarget: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var cropName: String
    var targetQuantity: Double
    var targetUnit: HarvestUnit
    var targetHarvestDate: Date?
    var priorityLevel: TaskPriority = .medium

    // Progress
    var bedsAssigned: Int = 0
    var estimatedYield: Double = 0
    var actualPlanted: Int = 0
}

struct PlantingScheduleEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var plantingDate: Date
    var cropName: String
    var varieties: [String] = []
    var bedsRequired: Int
    var assignedBedIds: [String] = []
    var isCompleted: Bool = false
    var notes: String?
}

enum PlanningStatus: String, Codable, CaseIterable, Hashable {
    case draft = "draft"
    case active = "active"
    case inProgress = "inProgress"
    case completed = "completed"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
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

