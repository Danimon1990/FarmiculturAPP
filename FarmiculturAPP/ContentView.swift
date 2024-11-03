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

            HarvestView(totalSeeds: crops.reduce(0) { $0 + $1.seedsPlanted })
                .tabItem {
                    Label("Harvest", systemImage: "tray.full")
                }
        }
        .onAppear {
            initializeCrops()
        }
    }

    func initializeCrops() {
        CropsDataManager.shared.initializeCropsIfNeeded()
        crops = CropsDataManager.shared.loadCrops()
    }

    func saveCrops() {
        CropsDataManager.shared.saveCrops(crops)
    }
}
