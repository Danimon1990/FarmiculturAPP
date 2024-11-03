//
//  CropsDataManager.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/24/24.
//

import Foundation

class CropsDataManager {
    static let shared = CropsDataManager()
    private let fileName = "crops.json"
    
    private var documentURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
    }

    // Load crops from JSON
    func loadCrops() -> [Crop] {
        guard let fileURL = documentURL else { return [] }

        do {
            let data = try Data(contentsOf: fileURL)
            let crops = try JSONDecoder().decode([Crop].self, from: data)
            print("Crops successfully loaded from: \(fileURL.path)")
            return crops
        } catch {
            print("Failed to load crops: \(error)")
            return []
        }
    }

    // Save crops to JSON
    func saveCrops(_ crops: [Crop]) {
        guard let fileURL = documentURL else {
            print("Failed to get the document URL.")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970 // Ensure consistent date encoding
            let data = try encoder.encode(crops)
            try data.write(to: fileURL)
            print("Crops successfully saved to: \(fileURL.path)")
        } catch {
            print("Failed to save crops: \(error)")
        }
    }

    // Copy the bundled JSON to the Documents Directory (if needed)
    func initializeCropsIfNeeded() {
        guard let fileURL = documentURL else { return }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            if let bundleURL = Bundle.main.url(forResource: "crops", withExtension: "json") {
                do {
                    try FileManager.default.copyItem(at: bundleURL, to: fileURL)
                    print("Copied crops.json to Documents Directory.")
                } catch {
                    print("Failed to copy crops.json: \(error)")
                }
            } else {
                print("crops.json not found in the app bundle.")
            }
        }
    }
}
