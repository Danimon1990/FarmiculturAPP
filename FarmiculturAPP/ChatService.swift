//
//  ChatService.swift
//  FarmiculturAPP
//
//  Service for handling AI chat interactions with Claude
//

import Foundation

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let farmService: FarmDataService
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"

    // System prompt that guides Claude's behavior
    private let systemPrompt = """
    You are an AI assistant for a farm management application called FarmiculturAPP. Your role is to help farmers understand their farm operations, track progress, and make informed decisions.

    When responding:
    - Be concise but friendly and conversational
    - Use clear, practical language that farmers understand
    - Provide specific numbers and data when available
    - Offer helpful suggestions and insights
    - Ask clarifying questions when needed
    - Format your responses in a readable way with line breaks and bullet points when appropriate
    - When discussing tasks, be encouraging and ask if the farmer wants to add more

    You have access to real-time farm data including:
    - Crop areas (greenhouses, outdoor fields, etc.)
    - Bed status (available, planted, growing, harvesting)
    - Active crops being grown
    - Upcoming tasks and priorities
    - Harvest information

    Always provide accurate information based on the data provided to you.
    """

    init(farmService: FarmDataService, apiKey: String) {
        self.farmService = farmService
        self.apiKey = apiKey
    }

    // MARK: - Public Methods

    func sendMessage(_ userMessage: String) async {
        // Add user message to chat
        let newMessage = ChatMessage(role: .user, content: userMessage)
        messages.append(newMessage)

        // Create loading message
        let loadingMessage = ChatMessage(role: .assistant, content: "", isLoading: true)
        messages.append(loadingMessage)
        isLoading = true
        errorMessage = nil

        do {
            // Check if this is a status query
            let isStatusQuery = isAskingForStatus(userMessage)

            // Get farm context
            let farmContext = try await getFarmContext(includeFullStatus: isStatusQuery)

            // Build conversation history for Claude
            let claudeMessages = buildClaudeMessages(farmContext: farmContext)

            // Call Claude API
            let response = try await callClaudeAPI(messages: claudeMessages)

            // Remove loading message and add real response
            messages.removeLast()
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)

        } catch {
            // Remove loading message and show error
            messages.removeLast()
            errorMessage = error.localizedDescription
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an error: \(error.localizedDescription)"
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func isAskingForStatus(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        let statusKeywords = [
            "status", "how is", "overview", "summary",
            "what's happening", "current", "today",
            "give me", "show me", "tell me about"
        ]

        return statusKeywords.contains { keyword in
            lowerMessage.contains(keyword)
        }
    }

    private func getFarmContext(includeFullStatus: Bool) async throws -> String {
        guard includeFullStatus else {
            return "Farm context available. Ask me about your farm operations."
        }

        // Get comprehensive farm status
        let status = try await farmService.getFarmStatusSummary()

        // Format as readable text for Claude
        var context = "CURRENT FARM STATUS (as of \(formatDate(status.date))):\n\n"

        // Crop Areas
        context += "🏗️ CROP AREAS (\(status.totalCropAreas) total):\n"
        for (type, count) in status.cropAreaBreakdown.sorted(by: { $0.key < $1.key }) {
            context += "  - \(count) \(type)\(count == 1 ? "" : "s")\n"
        }
        context += "\n"

        // Active Crops
        if !status.activeCrops.isEmpty {
            context += "🌱 CURRENTLY GROWING (\(status.activeCrops.count) crops):\n"
            context += "  " + status.activeCrops.joined(separator: ", ") + "\n\n"
        } else {
            context += "🌱 CURRENTLY GROWING: No active crops\n\n"
        }

        // Bed Status
        context += "🛏️ BED STATUS:\n"
        context += "  - Total beds: \(status.bedStatusCounts.total)\n"
        context += "  - Available for planting: \(status.bedStatusCounts.available)\n"
        context += "  - Planted: \(status.bedStatusCounts.planted)\n"
        context += "  - Growing: \(status.bedStatusCounts.growing)\n"
        context += "  - Ready for harvest: \(status.bedStatusCounts.harvesting)\n\n"

        // Tasks
        if !status.upcomingTasks.isEmpty {
            context += "✅ UPCOMING TASKS (\(status.upcomingTasks.count)):\n"
            for (index, task) in status.upcomingTasks.enumerated() {
                let dueDateStr = task.dueDate.map { " (due \(formatDate($0)))" } ?? ""
                context += "  \(index + 1). \(task.title)\(dueDateStr)\n"
            }
        } else {
            context += "✅ UPCOMING TASKS: No pending tasks\n"
        }

        return context
    }

    private func buildClaudeMessages(farmContext: String) -> [ClaudeMessage] {
        var claudeMessages: [ClaudeMessage] = []

        // Add farm context as the first message if we have data
        if !farmContext.isEmpty {
            claudeMessages.append(ClaudeMessage(
                role: "user",
                content: "Here is the current farm data:\n\n\(farmContext)"
            ))
            claudeMessages.append(ClaudeMessage(
                role: "assistant",
                content: "I've received the farm data and I'm ready to help you. What would you like to know?"
            ))
        }

        // Add conversation history (skip loading messages)
        for message in messages where !message.isLoading {
            claudeMessages.append(ClaudeMessage(
                role: message.role.rawValue,
                content: message.content
            ))
        }

        return claudeMessages
    }

    private func callClaudeAPI(messages: [ClaudeMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw ChatError.noAPIKey
        }

        // Prepare request
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody = ClaudeRequest(
            model: "claude-3-5-sonnet-20241022",
            maxTokens: 1024,
            messages: messages,
            system: systemPrompt
        )

        request.httpBody = try JSONEncoder().encode(requestBody)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorBody = String(data: data, encoding: .utf8) {
                print("API Error: \(errorBody)")
            }
            throw ChatError.networkError(
                NSError(domain: "ClaudeAPI", code: httpResponse.statusCode,
                       userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            )
        }

        // Parse response
        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let firstContent = claudeResponse.content.first else {
            throw ChatError.invalidResponse
        }

        return firstContent.text
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
