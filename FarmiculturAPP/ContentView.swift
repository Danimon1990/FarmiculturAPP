//
//  ContentView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//

import SwiftUI

struct ContentView: View {
    @State private var crops: [Crop] = []
    @State private var totalSeeds: Int = 0
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        TabView {
            HomeView(crops: $crops)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CropsView(crops: $crops, saveAction: saveCrops)
                .tabItem {
                    Label("Crops", systemImage: "leaf")
                }

            HarvestSummaryView(crops: $crops)
                .tabItem {
                    Label("Harvest", systemImage: "tray.full")
                }
        }
        .onAppear {
            initializeCrops()
        }
        .navigationBarItems(trailing: signOutButton)
        .task {
            await loadCropsFromFirebase()
        }
    }
    
    private var signOutButton: some View {
        Button("Sign Out") {
            firebaseService.signOut()
        }
        .foregroundColor(.red)
    }

    func initializeCrops() {
        CropsDataManager.shared.initializeCropsIfNeeded()
        crops = CropsDataManager.shared.loadCrops()
    }

    func saveCrops() {
        CropsDataManager.shared.saveCrops(crops)
        // Also save to Firebase
        Task {
            for crop in crops {
                await firebaseService.saveCrop(crop)
            }
        }
    }
    
    func loadCropsFromFirebase() async {
        let firebaseCrops = await firebaseService.loadCrops()
        DispatchQueue.main.async {
            if !firebaseCrops.isEmpty {
                self.crops = firebaseCrops
                // Update local storage as backup
                CropsDataManager.shared.saveCrops(firebaseCrops)
            }
        }
    }
}
