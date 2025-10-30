//
//  ChatView.swift
//  FarmiculturAPP
//
//  AI Chat interface for farm management
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var farmService: FarmDataService
    @StateObject private var chatService: ChatService
    @State private var messageText = ""
    @State private var showingAPIKeyAlert = false
    @State private var apiKeyInput = ""
    @FocusState private var isInputFocused: Bool

    init() {
        // Initialize with empty API key - user will set it
        let apiKey = UserDefaults.standard.string(forKey: "ClaudeAPIKey") ?? ""
        _chatService = StateObject(wrappedValue: ChatService(
            farmService: FarmDataService.shared,
            apiKey: apiKey
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if chatService.messages.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(chatService.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatService.messages.count) { _ in
                        // Auto-scroll to latest message
                        if let lastMessage = chatService.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Bar
                HStack(spacing: 12) {
                    TextField("Ask about your farm...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(messageText.isEmpty ? Color.gray : Color.green)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty || chatService.isLoading)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Farm AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAPIKeyAlert = true }) {
                            Label("Set API Key", systemImage: "key")
                        }
                        Button(action: { chatService.clearChat() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Claude API Key", isPresented: $showingAPIKeyAlert) {
                TextField("sk-ant-...", text: $apiKeyInput)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    saveAPIKey()
                }
            } message: {
                Text("Enter your Claude API key from console.anthropic.com")
            }
            .onAppear {
                checkAPIKey()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.green.opacity(0.6))

            Text("Welcome to Farm AI Assistant")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ask me anything about your farm")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                SuggestionButton(text: "How is the farm today?") {
                    messageText = "How is the farm today?"
                }
                SuggestionButton(text: "Give me a status update") {
                    messageText = "Give me a status update"
                }
                SuggestionButton(text: "What tasks are coming up?") {
                    messageText = "What tasks are coming up?"
                }
                SuggestionButton(text: "What crops are we growing?") {
                    messageText = "What crops are we growing?"
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.top, 40)
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = messageText
        messageText = ""
        isInputFocused = false

        Task {
            await chatService.sendMessage(message)
        }
    }

    private func checkAPIKey() {
        let apiKey = UserDefaults.standard.string(forKey: "ClaudeAPIKey") ?? ""
        if apiKey.isEmpty {
            // Show alert after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAPIKeyAlert = true
            }
        }
    }

    private func saveAPIKey() {
        UserDefaults.standard.set(apiKeyInput, forKey: "ClaudeAPIKey")
        // Reinitialize chat service with new key
        chatService.clearChat()
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray5))
                    .cornerRadius(18)
                } else {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.role == .user ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            message.role == .user
                                ? Color.green
                                : Color(.systemGray5)
                        )
                        .cornerRadius(18)
                }

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer(minLength: 50)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Suggestion Button

struct SuggestionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .environmentObject(FarmDataService.shared)
    }
}
