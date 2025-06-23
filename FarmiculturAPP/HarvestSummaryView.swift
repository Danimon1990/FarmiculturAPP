import SwiftUI

struct HarvestSummaryView: View {
    @Binding var crops: [Crop]
    
    var harvestablePlants: [Crop] {
        let filtered = crops.filter { crop in
            crop.isHarvestable
        }
        return filtered
    }
    
    var totalSeeds: Int {
        crops.reduce(0) { $0 + $1.seedsPlanted }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Seeds Planted")
                        Spacer()
                        Text("\(totalSeeds)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Plants Ready to Harvest")
                        Spacer()
                        Text("\(harvestablePlants.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section(header: Text("Ready to Harvest")) {
                //     if harvestablePlants.isEmpty {
                //         Text("No plants ready for harvest")
                //             .foregroundColor(.secondary)
                //     } else {
                //         ForEach(harvestablePlants) { crop in
                //             NavigationLink(destination: HarvestView(
                //                 sectionIndex: crop.sectionIndex,
                //                 bedIndex: crop.bedIndex,
                //                 crop: $crops[crop.sectionIndex].beds[crop.bedIndex]
                //             )) {
                //                 VStack(alignment: .leading) {
                //                     Text(crop.name)
                //                         .font(.headline)
                //                     Text("Section \(crop.sectionIndex + 1), Bed \(crop.bedIndex + 1)")
                //                         .font(.subheadline)
                //                         .foregroundColor(.secondary)
                //                 }
                //             }
                //         }
                //     }
                // }
                Section(header: Text("Ready to Harvest")) {
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Harvest")
        }
    }
}
