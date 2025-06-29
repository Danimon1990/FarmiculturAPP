import SwiftUI

struct HomeView: View {
    @Binding var crops: [Crop]
    let saveAction: () -> Void
    @EnvironmentObject var firebaseService: FirebaseService
    @State private var recentModifications: [CropModification] = []
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Dynamic Greeting
                Text(dynamicGreeting())
                    .font(.largeTitle)
                    .padding(.horizontal)

                // Tasks List
                if pendingTasks().isEmpty {
                    Text("No pending tasks 🎉").font(.headline).padding(.horizontal)
                } else {
                    Text("Pending Tasks:")
                        .font(.headline)
                        .padding(.horizontal)
                    List {
                        ForEach(allTasks()) { task in
                            HStack {
                                // Mark Task as Completed
                                Button(action: {
                                    markTaskAsCompleted(task)
                                }) {
                                    Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                        .foregroundColor(task.isCompleted ? .green : .gray)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                // Task Details
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(.body)
                                    Text("From: \(cropName(for: task.cropID))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let due = task.dueDate {
                                        Text("Due: \(due, formatter: dateFormatter)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                
                // Recent Activity Section
                if !recentModifications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Activity:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(recentModifications.prefix(5)) { modification in
                                    HStack {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text("\(modification.cropName) updated")
                                                .font(.subheadline)
                                            Text("by \(modification.modifiedBy)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(modification.modifiedAt, formatter: relativeDateFormatter)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                }
            }
            .navigationTitle("Home")
            .onAppear {
                loadRecentActivity()
            }
        }
    }

    // MARK: - Helper Functions
    private func dynamicGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "Good Morning, Farmer! 🌞"
        case 12..<18: return "Good Afternoon, Farmer! 🌻"
        default: return "Good Evening, Farmer! 🌙"
        }
    }
    
    private func allTasks() -> [CropTask] {
        crops.flatMap { $0.tasks }
    }
    
    private func pendingTasks() -> [CropTask] {
        allTasks().filter { !$0.isCompleted }
    }
    
    private func cropName(for id: String) -> String {
        crops.first(where: { $0.id == id })?.name ?? "Unknown"
    }
    
    // Mark a task as completed
    private func markTaskAsCompleted(_ task: CropTask) {
        if let cropIndex = crops.firstIndex(where: { $0.id == task.cropID }),
           let taskIndex = crops[cropIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            crops[cropIndex].tasks[taskIndex].isCompleted.toggle()
            saveAction() // Save the crop when a task is marked as completed
        }
    }

    private func loadRecentActivity() {
        Task {
            recentModifications = await firebaseService.getRecentCropModifications(limit: 10)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .none
    return df
}()

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
}()
