import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
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
            currentUser = result.user
            isAuthenticated = true
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
            
            // Create user profile for shared data system
            await updateUserProfile(displayName: email.components(separatedBy: "@").first ?? "User")
            
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
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Firestore Operations
    
    func saveCrop(_ crop: Crop) async {
        guard let currentUser = currentUser else { return }
        
        do {
            let cropData = try convertCropToFirebaseData(crop, userId: currentUser.uid)
            try await db.collection("shared_crops").document(crop.id)
                .setData(cropData)
        } catch {
            errorMessage = "Failed to save crop: \(error.localizedDescription)"
        }
    }
    
    func loadCrops() async -> [Crop] {
        do {
            let snapshot = try await db.collection("shared_crops").getDocuments()
            
            let crops = snapshot.documents.compactMap { document in
                try? convertFirebaseDataToCrop(document.data(), id: document.documentID)
            }
            
            return crops
        } catch {
            errorMessage = "Failed to load crops: \(error.localizedDescription)"
            return []
        }
    }
    
    func deleteCrop(_ cropId: String) async {
        do {
            try await db.collection("shared_crops").document(cropId)
                .delete()
        } catch {
            errorMessage = "Failed to delete crop: \(error.localizedDescription)"
        }
    }
    
    func updateCropModification(_ cropId: String) async {
        guard let currentUser = currentUser else { return }
        
        do {
            try await db.collection("shared_crops").document(cropId)
                .updateData([
                    "lastModifiedBy": currentUser.uid,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
        } catch {
            errorMessage = "Failed to update crop modification: \(error.localizedDescription)"
        }
    }
    
    // MARK: - User Management for Shared Data
    
    func getUserDisplayName(_ userId: String) async -> String {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(),
               let displayName = data["displayName"] as? String {
                return displayName
            }
        } catch {
            print("Failed to get user display name: \(error)")
        }
        return "Unknown User"
    }
    
    func updateUserProfile(displayName: String) async {
        guard let currentUser = currentUser else { return }
        
        do {
            try await db.collection("users").document(currentUser.uid).setData([
                "displayName": displayName,
                "email": currentUser.email ?? "",
                "lastUpdated": FieldValue.serverTimestamp()
            ], merge: true)
        } catch {
            errorMessage = "Failed to update user profile: \(error.localizedDescription)"
        }
    }
    
    func getCurrentUserDisplayName() -> String {
        return currentUser?.displayName ?? currentUser?.email ?? "Unknown User"
    }
    
    func getRecentCropModifications(limit: Int = 10) async -> [CropModification] {
        do {
            let snapshot = try await db.collection("shared_crops")
                .order(by: "updatedAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var modifications: [CropModification] = []
            
            for document in snapshot.documents {
                let data = document.data()
                if let name = data["name"] as? String,
                   let lastModifiedBy = data["lastModifiedBy"] as? String,
                   let updatedAt = data["updatedAt"] as? Timestamp {
                    
                    let displayName = await getUserDisplayName(lastModifiedBy)
                    modifications.append(CropModification(
                        cropName: name,
                        modifiedBy: displayName,
                        modifiedAt: updatedAt.dateValue()
                    ))
                }
            }
            
            return modifications
        } catch {
            errorMessage = "Failed to get recent modifications: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Data Conversion
    
    private func convertCropToFirebaseData(_ crop: Crop, userId: String) throws -> [String: Any] {
        // Convert sections to a flat structure - store as separate documents
        let sectionsData = crop.sections.enumerated().map { sectionIndex, section in
            section.enumerated().map { bedIndex, bed in
                [
                    "sectionIndex": sectionIndex,
                    "bedIndex": bedIndex,
                    "bedId": bed.id.uuidString,
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
        }.flatMap { $0 }
        
        let activitiesData = crop.activities.map { activity in
            [
                "id": activity.id.uuidString,
                "name": activity.name,
                "description": activity.activityDescription,
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
        
        let tasksData = crop.tasks.map { task in
            [
                "id": task.id,
                "title": task.title,
                "taskDescription": task.taskDescription,
                "dueDate": task.dueDate != nil ? Timestamp(date: task.dueDate!) : nil,
                "isCompleted": task.isCompleted,
                "cropID": task.cropID
            ]
        }
        
        return [
            "id": crop.id,
            "createdBy": userId,
            "lastModifiedBy": userId,
            "type": crop.type.rawValue,
            "name": crop.name,
            "isActive": crop.isActive,
            "sections": sectionsData, // Now a flat array instead of nested
            "beds": [], // We'll handle beds separately if needed
            "sectionLength": crop.sectionLength,
            "sectionWidth": crop.sectionWidth,
            "activities": activitiesData,
            "tasks": tasksData,
            "expectedHarvestDate": Timestamp(date: crop.expectedHarvestDate),
            "seedVariety": crop.seedVariety,
            "numberOfSeeds": crop.numberOfSeeds,
            "treeVariety": crop.treeVariety,
            "numberOfTrees": crop.numberOfTrees,
            "observations": observationsData,
            "seedStartDate": crop.seedStartDate != nil ? Timestamp(date: crop.seedStartDate!) : nil,
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
              let expectedHarvestTimestamp = data["expectedHarvestDate"] as? Timestamp,
              let seedsPlanted = data["seedsPlanted"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        let expectedHarvestDate = expectedHarvestTimestamp.dateValue()
        let seedStartDate = (data["seedStartDate"] as? Timestamp)?.dateValue()
        
        // Convert flat sections data back to nested structure
        let sectionsData = data["sections"] as? [[String: Any]] ?? []
        let sections = reconstructSections(from: sectionsData)
        
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
        
        // Convert tasks
        let tasksData = data["tasks"] as? [[String: Any]] ?? []
        let tasks = tasksData.compactMap { taskData in
            convertTaskData(taskData)
        }
        
        return Crop(
            id: id,
            type: type,
            name: name,
            isActive: isActive,
            sections: sections,
            beds: [], // We'll reconstruct from sections
            sectionLength: sectionLength,
            sectionWidth: sectionWidth,
            activities: activities,
            expectedHarvestDate: expectedHarvestDate,
            seedVariety: data["seedVariety"] as? String,
            numberOfSeeds: data["numberOfSeeds"] as? Int,
            treeVariety: data["treeVariety"] as? String,
            numberOfTrees: data["numberOfTrees"] as? Int,
            observations: observations,
            seedStartDate: seedStartDate,
            seedLocation: data["seedLocation"] as? String,
            seedsPlanted: seedsPlanted,
            potSize: data["potSize"] as? String,
            soilUsed: data["soilUsed"] as? String,
            tasks: tasks
        )
    }
    
    private func reconstructSections(from flatData: [[String: Any]]) -> [[Bed]] {
        var sections: [Int: [Bed]] = [:]
        
        for bedData in flatData {
            guard let sectionIndex = bedData["sectionIndex"] as? Int,
                  let bed = convertBedData(bedData) else { continue }
            
            if sections[sectionIndex] == nil {
                sections[sectionIndex] = []
            }
            sections[sectionIndex]?.append(bed)
        }
        
        if sections.isEmpty {
            return []
        }
        
        // Convert back to array format
        let maxSectionIndex = sections.keys.max() ?? -1
        return (0...maxSectionIndex).map { index in
            sections[index] ?? []
        }
    }
    
    private func convertBedData(_ data: [String: Any]) -> Bed? {
        guard let idString = data["bedId"] as? String,
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
              let dateTimestamp = data["date"] as? Timestamp else {
            return nil
        }
        
        return Activity(
            id: id,
            name: name,
            activityDescription: data["description"] as? String,
            isCompleted: isCompleted,
            date: dateTimestamp.dateValue()
        )
    }
    
    private func convertObservationData(_ data: [String: Any]) -> Observation? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let dateTimestamp = data["date"] as? Timestamp,
              let text = data["text"] as? String else {
            return nil
        }
        
        return Observation(id: id, date: dateTimestamp.dateValue(), text: text)
    }
    
    private func convertTaskData(_ data: [String: Any]) -> CropTask? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let taskDescription = data["taskDescription"] as? String,
              let isCompleted = data["isCompleted"] as? Bool,
              let cropID = data["cropID"] as? String else {
            return nil
        }
        
        let dueDate = (data["dueDate"] as? Timestamp)?.dateValue()
        
        return CropTask(
            id: id,
            title: title,
            taskDescription: taskDescription,
            dueDate: dueDate,
            isCompleted: isCompleted,
            cropID: cropID
        )
    }
}

enum FirebaseError: Error {
    case invalidData
    case authenticationFailed
    case networkError
}

// MARK: - Helper Structs

struct CropModification: Identifiable {
    let id = UUID()
    let cropName: String
    let modifiedBy: String
    let modifiedAt: Date
} 