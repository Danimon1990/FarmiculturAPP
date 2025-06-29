import Foundation

struct CropTask: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var taskDescription: String // Renamed from 'description' to avoid potential conflicts
    var dueDate: Date?
    var isCompleted: Bool = false
    var cropID: String // Link to Crop
} 