//
//  ContentView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//

import SwiftUI

struct ContentView: View {
    @State private var crops: [Crop] = []
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        TabView {
            HomeView(crops: $crops, saveAction: saveCrops)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            CropsView(crops: $crops, saveAction: saveCrops)
                .tabItem {
                    Label("Crops", systemImage: "leaf")
                }

            HarvestSummaryView(crops: $crops, saveAction: saveCrops)
                .tabItem {
                    Label("Harvest", systemImage: "tray.full")
                }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                signOutButton
            }
        }
        .onAppear {
            Task {
                await loadCrops()
            }
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            firebaseService.signOut()
        }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundColor(.red)
        }
    }

    func saveCrops() {
        CropsDataManager.shared.saveCrops(crops)
        Task {
            for crop in crops {
                await firebaseService.saveCrop(crop)
            }
        }
    }
    
    func loadCrops() async {
        let firebaseCrops = await firebaseService.loadCrops()
        if !firebaseCrops.isEmpty {
            self.crops = firebaseCrops
            CropsDataManager.shared.saveCrops(firebaseCrops)
        } else {
            self.crops = CropsDataManager.shared.loadCrops()
        }
    }
}
