//
//  HomeView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import SwiftUI

struct HomeView: View {
    @Binding var crops: [Crop]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                // Welcome Text
                Text("Hello fuckers! Is time to work! go make money bitches! and roll it and burn it but work!")
                    .font(.headline)
                    .padding()

                // List of Activities
                List {
                    ForEach(crops) { crop in
                        ForEach(crop.activities.filter { !$0.isCompleted }) { activity in
                            HStack {
                                Button(action: {
                                    markActivityAsCompleted(activity, in: crop)
                                }) {
                                    Image(systemName: "checkmark.square")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
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
            .navigationTitle("Home")
        }
    }

    // MARK: - Helper Functions
    private func markActivityAsCompleted(_ activity: Activity, in crop: Crop) {
        if let cropIndex = crops.firstIndex(where: { $0.id == crop.id }),
           let activityIndex = crops[cropIndex].activities.firstIndex(where: { $0.id == activity.id }) {
            crops[cropIndex].activities[activityIndex].isCompleted = true
        }
    }
}
