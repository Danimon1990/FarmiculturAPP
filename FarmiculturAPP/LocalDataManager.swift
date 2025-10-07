//
//  LocalDataManager.swift
//  FarmiculturAPP
//
//  Local storage for offline support
//

import Foundation

class LocalDataManager {
    static let shared = LocalDataManager()
    
    private let fileManager = FileManager.default
    private var documentDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private init() {}
    
    // MARK: - Generic Save/Load
    
    private func save<T: Codable>(_ data: T, to filename: String) {
        guard let url = documentDirectory?.appendingPathComponent(filename) else {
            print("Failed to get document directory")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url)
            print("✅ Saved \(filename)")
        } catch {
            print("❌ Failed to save \(filename): \(error)")
        }
    }
    
    private func load<T: Codable>(from filename: String) -> T? {
        guard let url = documentDirectory?.appendingPathComponent(filename) else {
            print("Failed to get document directory")
            return nil
        }
        
        guard fileManager.fileExists(atPath: url.path) else {
            print("File does not exist: \(filename)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(T.self, from: data)
            print("✅ Loaded \(filename)")
            return decoded
        } catch {
            print("❌ Failed to load \(filename): \(error)")
            return nil
        }
    }
    
    // MARK: - Farm
    
    func saveFarm(_ farm: Farm) {
        save(farm, to: "farm.json")
    }
    
    func loadFarm() -> Farm? {
        return load(from: "farm.json")
    }
    
    // MARK: - Crop Areas
    
    func saveCropAreas(_ areas: [CropArea]) {
        save(areas, to: "cropAreas.json")
    }
    
    func loadCropAreas() -> [CropArea] {
        return load(from: "cropAreas.json") ?? []
    }
    
    // MARK: - Sections
    
    func saveSections(_ sections: [CropSection], for areaId: String) {
        save(sections, to: "sections_\(areaId).json")
    }
    
    func loadSections(for areaId: String) -> [CropSection] {
        return load(from: "sections_\(areaId).json") ?? []
    }
    
    // MARK: - Beds
    
    func saveBeds(_ beds: [Bed], for sectionId: String) {
        save(beds, to: "beds_\(sectionId).json")
    }
    
    func saveBed(_ bed: Bed, for sectionId: String) {
        var beds = loadBeds(for: sectionId)
        if let index = beds.firstIndex(where: { $0.id == bed.id }) {
            beds[index] = bed
        } else {
            beds.append(bed)
        }
        saveBeds(beds, for: sectionId)
    }
    
    func loadBeds(for sectionId: String) -> [Bed] {
        return load(from: "beds_\(sectionId).json") ?? []
    }
    
    func saveAllBeds(_ beds: [Bed], for areaId: String) {
        save(beds, to: "allBeds_\(areaId).json")
    }
    
    func loadAllBeds(for areaId: String) -> [Bed] {
        return load(from: "allBeds_\(areaId).json") ?? []
    }
    
    // MARK: - Harvest Reports
    
    func saveHarvestReports(_ reports: [HarvestReport]) {
        save(reports, to: "harvestReports.json")
    }
    
    func loadHarvestReports() -> [HarvestReport] {
        return load(from: "harvestReports.json") ?? []
    }
    
    // MARK: - Completed Beds
    
    func saveCompletedBeds(_ completedBeds: [CompletedBed]) {
        save(completedBeds, to: "completedBeds.json")
    }
    
    func loadCompletedBeds() -> [CompletedBed] {
        return load(from: "completedBeds.json") ?? []
    }
    
    // MARK: - Tasks
    
    func saveTasks(_ tasks: [BedTask]) {
        save(tasks, to: "tasks.json")
    }
    
    func loadTasks() -> [BedTask] {
        return load(from: "tasks.json") ?? []
    }
    
    // MARK: - Clear Data
    
    func clearAllData() {
        guard let directory = documentDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
                print("🗑 Deleted \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Failed to clear data: \(error)")
        }
    }
    
    // MARK: - User Preferences
    
    func saveCurrentFarmId(_ farmId: String) {
        UserDefaults.standard.set(farmId, forKey: "currentFarmId")
    }
    
    func loadCurrentFarmId() -> String? {
        return UserDefaults.standard.string(forKey: "currentFarmId")
    }
    
    func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "lastSyncDate")
    }
    
    func loadLastSyncDate() -> Date? {
        return UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
}

