//
//  Crop.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import Foundation
import SwiftUI

struct Activity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isCompleted: Bool = false
}
struct Observation: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var text: String
}

struct Crop: Identifiable, Codable {
    var id = UUID()
    var type: CropType
    var name: String
    var isActive: Bool
    var sections: [[Bed]]
    var beds: [[Bed]]?
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
    
}
extension Crop {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(CropType.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        sections = try container.decode([[Bed]].self, forKey: .sections)
        beds = try container.decodeIfPresent([[Bed]].self, forKey: .beds)
        sectionLength = try container.decode(Double.self, forKey: .sectionLength)
        sectionWidth = try container.decode(Double.self, forKey: .sectionWidth)
        activities = try container.decode([Activity].self, forKey: .activities)
        expectedHarvestDate = try container.decode(Date.self, forKey: .expectedHarvestDate)
        seedVariety = try container.decodeIfPresent(String.self, forKey: .seedVariety)
        numberOfSeeds = try container.decodeIfPresent(Int.self, forKey: .numberOfSeeds)
        treeVariety = try container.decodeIfPresent(String.self, forKey: .treeVariety)
        numberOfTrees = try container.decodeIfPresent(Int.self, forKey: .numberOfTrees)
        observations = try container.decodeIfPresent([Observation].self, forKey: .observations) ?? []
        seedStartDate = try container.decodeIfPresent(Date.self, forKey: .seedStartDate)
        seedLocation = try container.decodeIfPresent(String.self, forKey: .seedLocation)
        seedsPlanted = try container.decode(Int.self, forKey: .seedsPlanted)
        potSize = try container.decodeIfPresent(String.self, forKey: .potSize)
        soilUsed = try container.decodeIfPresent(String.self, forKey: .soilUsed)
    }
}


struct Bed: Identifiable, Codable, Hashable {
    var id = UUID()
    var section: Int
    var bed: Int
    var plantCount: Int
    var state: String  // Example: "Growing", "Empty", etc.
}

enum CropType: String, Codable, CaseIterable {
    case greenhouse = "Greenhouse"
    case seeds = "Seed Batch"
    case treeCrops = "Tree Crops"
    case outdoorBeds = "Outdoor Beds"
    case highTunnels = "High Tunnels"
}


