//
//  ChatModels.swift
//  FarmiculturAPP
//
//  Models for AI chat functionality
//

import Foundation

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var role: MessageRole
    var content: String
    var timestamp: Date = Date()
    var isLoading: Bool = false

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }
}

// MARK: - Farm Status Summary

struct FarmStatusSummary: Codable {
    let date: Date
    let totalCropAreas: Int
    let cropAreaBreakdown: [String: Int] // e.g., ["Greenhouse": 4, "Outdoor": 2]
    let activeCrops: [String] // Unique crop names currently growing
    let bedStatusCounts: BedStatusCounts
    let upcomingTasks: [TaskSummary]
    let recentHarvests: [HarvestSummary]?
    let availableWorkers: Int?

    struct BedStatusCounts: Codable {
        let available: Int
        let planted: Int
        let growing: Int
        let harvesting: Int
        let total: Int
    }

    struct TaskSummary: Codable {
        let title: String
        let dueDate: Date?
        let priority: String
    }

    struct HarvestSummary: Codable {
        let cropName: String
        let quantity: Double
        let unit: String
        let date: Date
    }
}

// MARK: - Claude API Models

struct ClaudeRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stopReason: String?
    let usage: ClaudeUsage?

    enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case usage
    }
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Error Types

enum ChatError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case noFarmData

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "Claude API key not configured"
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noFarmData:
            return "No farm data available"
        }
    }
}
