import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.currentUser = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firestore Operations
    
    func saveCrop(_ crop: Crop) async {
        guard let userId = currentUser?.uid else { return }
        
        do {
            let cropData = try convertCropToFirebaseData(crop, userId: userId)
            try await db.collection("users").document(userId)
                .collection("crops").document(crop.id)
                .setData(cropData)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to save crop: \(error.localizedDescription)"
            }
        }
    }
    
    func loadCrops() async -> [Crop] {
        guard let userId = currentUser?.uid else { return [] }
        
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("crops").getDocuments()
            
            let crops = snapshot.documents.compactMap { document in
                try? convertFirebaseDataToCrop(document.data(), id: document.documentID)
            }
            
            return crops
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load crops: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    func deleteCrop(_ cropId: String) async {
        guard let userId = currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId)
                .collection("crops").document(cropId)
                .delete()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to delete crop: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertCropToFirebaseData(_ crop: Crop, userId: String) throws -> [String: Any] {
        let sectionsData = crop.sections.map { section in
            section.map { bed in
                [
                    "id": bed.id.uuidString,
                    "section": bed.section,
                    "bed": bed.bed,
                    "plantCount": bed.plantCount,
                    "state": bed.state.rawValue,
                    "varieties": bed.varieties.map { variety in
                        [
                            "id": variety.id.uuidString,
                            "name": variety.name,
                            "count": variety.count
                        ]
                    }
                ]
            }
        }
        
        let bedsData = crop.beds.map { bed in
            [
                "id": bed.id.uuidString,
                "section": bed.section,
                "bed": bed.bed,
                "plantCount": bed.plantCount,
                "state": bed.state.rawValue,
                "varieties": bed.varieties.map { variety in
                    [
                        "id": variety.id.uuidString,
                        "name": variety.name,
                        "count": variety.count
                    ]
                }
            ]
        }
        
        let activitiesData = crop.activities.map { activity in
            [
                "id": activity.id.uuidString,
                "name": activity.name,
                "description": activity.description,
                "isCompleted": activity.isCompleted,
                "date": activity.date
            ]
        }
        
        let observationsData = crop.observations.map { observation in
            [
                "id": observation.id.uuidString,
                "date": observation.date,
                "text": observation.text
            ]
        }
        
        return [
            "id": crop.id,
            "userId": userId,
            "type": crop.type.rawValue,
            "name": crop.name,
            "isActive": crop.isActive,
            "sections": sectionsData,
            "beds": bedsData,
            "sectionLength": crop.sectionLength,
            "sectionWidth": crop.sectionWidth,
            "activities": activitiesData,
            "expectedHarvestDate": crop.expectedHarvestDate,
            "seedVariety": crop.seedVariety,
            "numberOfSeeds": crop.numberOfSeeds,
            "treeVariety": crop.treeVariety,
            "numberOfTrees": crop.numberOfTrees,
            "observations": observationsData,
            "seedStartDate": crop.seedStartDate,
            "seedLocation": crop.seedLocation,
            "seedsPlanted": crop.seedsPlanted,
            "potSize": crop.potSize,
            "soilUsed": crop.soilUsed,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
    }
    
    private func convertFirebaseDataToCrop(_ data: [String: Any], id: String) throws -> Crop {
        guard let typeString = data["type"] as? String,
              let type = CropType(rawValue: typeString),
              let name = data["name"] as? String,
              let isActive = data["isActive"] as? Bool,
              let sectionLength = data["sectionLength"] as? Double,
              let sectionWidth = data["sectionWidth"] as? Double,
              let expectedHarvestDate = data["expectedHarvestDate"] as? Date,
              let seedsPlanted = data["seedsPlanted"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        // Convert sections
        let sectionsData = data["sections"] as? [[[String: Any]]] ?? []
        let sections = sectionsData.map { section in
            section.compactMap { bedData in
                convertBedData(bedData)
            }
        }
        
        // Convert beds
        let bedsData = data["beds"] as? [[String: Any]] ?? []
        let beds = bedsData.compactMap { bedData in
            convertBedData(bedData)
        }
        
        // Convert activities
        let activitiesData = data["activities"] as? [[String: Any]] ?? []
        let activities = activitiesData.compactMap { activityData in
            convertActivityData(activityData)
        }
        
        // Convert observations
        let observationsData = data["observations"] as? [[String: Any]] ?? []
        let observations = observationsData.compactMap { observationData in
            convertObservationData(observationData)
        }
        
        return Crop(
            id: id,
            type: type,
            name: name,
            isActive: isActive,
            sections: sections,
            beds: beds,
            sectionLength: sectionLength,
            sectionWidth: sectionWidth,
            activities: activities,
            expectedHarvestDate: expectedHarvestDate,
            seedVariety: data["seedVariety"] as? String,
            numberOfSeeds: data["numberOfSeeds"] as? Int,
            treeVariety: data["treeVariety"] as? String,
            numberOfTrees: data["numberOfTrees"] as? Int,
            observations: observations,
            seedStartDate: data["seedStartDate"] as? Date,
            seedLocation: data["seedLocation"] as? String,
            seedsPlanted: seedsPlanted,
            potSize: data["potSize"] as? String,
            soilUsed: data["soilUsed"] as? String
        )
    }
    
    private func convertBedData(_ data: [String: Any]) -> Bed? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let section = data["section"] as? Int,
              let bed = data["bed"] as? Int,
              let plantCount = data["plantCount"] as? Int,
              let stateString = data["state"] as? String,
              let state = BedState(rawValue: stateString) else {
            return nil
        }
        
        let varietiesData = data["varieties"] as? [[String: Any]] ?? []
        let varieties = varietiesData.compactMap { varietyData in
            convertVarietyData(varietyData)
        }
        
        return Bed(
            id: id,
            section: section,
            bed: bed,
            plantCount: plantCount,
            state: state,
            varieties: varieties
        )
    }
    
    private func convertVarietyData(_ data: [String: Any]) -> PlantVariety? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let count = data["count"] as? Int else {
            return nil
        }
        
        return PlantVariety(id: id, name: name, count: count)
    }
    
    private func convertActivityData(_ data: [String: Any]) -> Activity? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let isCompleted = data["isCompleted"] as? Bool,
              let date = data["date"] as? Date else {
            return nil
        }
        
        return Activity(
            id: id,
            name: name,
            description: data["description"] as? String,
            isCompleted: isCompleted,
            date: date
        )
    }
    
    private func convertObservationData(_ data: [String: Any]) -> Observation? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let date = data["date"] as? Date,
              let text = data["text"] as? String else {
            return nil
        }
        
        return Observation(id: id, date: date, text: text)
    }
}

enum FirebaseError: Error {
    case invalidData
    case authenticationFailed
    case networkError
} 