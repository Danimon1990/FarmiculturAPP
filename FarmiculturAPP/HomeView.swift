
import SwiftUI


struct HomeView: View {
    @Binding var crops: [Crop]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Dynamic Greeting
                Text(dynamicGreeting())
                    .font(.largeTitle)
                    .padding(.horizontal)

                // Activities List
                if pendingActivities().isEmpty {
                    Text("No pending activities 🎉").font(.headline).padding(.horizontal)
                } else {
                    Text("Pending Activities:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(crops) { crop in
                            ForEach(crop.activities.filter { !$0.isCompleted }) { activity in
                                HStack {
                                    // Mark Activity as Completed
                                    Button(action: {
                                        markActivityAsCompleted(activity, in: crop)
                                    }) {
                                        Image(systemName: "checkmark.square")
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    
                                    // Activity Details
                                    VStack(alignment: .leading) {
                                        Text(activity.name)
                                            .font(.body)
                                        Text("From: \(crop.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Home")
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
    private func pendingActivities() -> [Activity] {
            crops.flatMap { crop in
                crop.activities.filter { !$0.isCompleted }
            }
        }
        
        // Mark an activity as completed
        private func markActivityAsCompleted(_ activity: Activity, in crop: Crop) {
            if let cropIndex = crops.firstIndex(where: { $0.id == crop.id }),
               let activityIndex = crops[cropIndex].activities.firstIndex(where: { $0.id == activity.id }) {
                crops[cropIndex].activities[activityIndex].isCompleted = true
            }
    }
}
