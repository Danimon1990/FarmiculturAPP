//
//  FarmiculturAPPApp.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct FarmiculturAPPApp: App {
    @StateObject private var farmDataService = FarmDataService.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if farmDataService.isAuthenticated {
                MainAppView()
                    .environmentObject(farmDataService)
            } else {
                AuthView()
                    .environmentObject(farmDataService)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
