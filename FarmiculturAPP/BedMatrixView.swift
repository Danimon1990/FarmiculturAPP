//
//  BedMatrixView.swift
//  FarmiculturAPP
//
//  Bed matrix view for section detail
//

import SwiftUI

struct BedMatrixView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Binding var beds: [Bed]
    let area: CropArea
    let section: CropSection
    let onBedSelected: (Bed) -> Void
    @State private var bedToDelete: Bed?
    @State private var showingDeleteBedAlert = false
    
    // Sort beds by bed number for consistent display
    var sortedBeds: [Bed] {
        beds.sorted { bed1, bed2 in
            // Extract numbers from bed numbers for proper sorting
            let num1 = extractNumber(from: bed1.bedNumber)
            let num2 = extractNumber(from: bed2.bedNumber)
            return num1 < num2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tap a bed to view details")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sortedBeds) { bed in
                        BedMatrixItemView(bed: bed)
                            .onTapGesture {
                                onBedSelected(bed)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteBed(bed)
                                } label: {
                                    Label("Delete Bed", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .alert("Delete Bed", isPresented: $showingDeleteBedAlert) {
            Button("Cancel", role: .cancel) {
                bedToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let bed = bedToDelete {
                    performDeleteBed(bed)
                }
            }
        } message: {
            if let bed = bedToDelete {
                Text("Are you sure you want to delete bed '\(bed.bedNumber)'? This will also delete all harvest history for this bed. This action cannot be undone.")
            }
        }
    }
    
    func extractNumber(from bedNumber: String) -> Int {
        // Extract the last number from bed number (e.g., "GREENHOUSE-A-1" -> 1, "FIELD-B-12" -> 12)
        let components = bedNumber.components(separatedBy: "-")
        if let lastComponent = components.last {
            return Int(lastComponent) ?? 0
        }
        return 0
    }
    
    func deleteBed(_ bed: Bed) {
        bedToDelete = bed
        showingDeleteBedAlert = true
    }
    
    func performDeleteBed(_ bed: Bed) {
        Task {
            do {
                try await farmService.deleteBed(bedId: bed.id, sectionId: section.id, areaId: area.id)
                beds.removeAll { $0.id == bed.id }
                print("✅ Deleted bed: \(bed.bedNumber)")
            } catch {
                print("❌ Failed to delete bed: \(error)")
            }
        }
        bedToDelete = nil
    }
}

struct BedMatrixItemView: View {
    let bed: Bed
    
    var body: some View {
        VStack(spacing: 2) {
            // Plant count in bold
            Text("\(bed.totalPlantCount)")
                .font(.caption)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Status text
            Text(bed.status.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            // Plant name
            Text(plantName)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(width: 60, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(bed.status.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(bed.status.color.opacity(0.4), lineWidth: 1.5)
                )
        )
    }
    
    private var plantName: String {
        if bed.varieties.isEmpty {
            return "Empty"
        } else if bed.varieties.count == 1 {
            return bed.varieties[0].name
        } else {
            return "\(bed.varieties.count) varieties"
        }
    }
}

struct BedMatrixView_Previews: PreviewProvider {
    static var previews: some View {
        @State var beds = [
            Bed(sectionId: "1", cropAreaId: "1", bedNumber: "GREENHOUSE-A-1", status: .dirty),
            Bed(sectionId: "1", cropAreaId: "1", bedNumber: "GREENHOUSE-A-2", status: .clean),
            Bed(sectionId: "1", cropAreaId: "1", bedNumber: "GREENHOUSE-A-3", status: .growing, varieties: [PlantVariety(name: "Cherry Tomatoes", count: 12)]),
            Bed(sectionId: "1", cropAreaId: "1", bedNumber: "GREENHOUSE-A-4", status: .harvesting, varieties: [PlantVariety(name: "Lettuce", count: 8)])
        ]
        let area = CropArea(farmId: "1", name: "Test Area", type: .greenhouse)
        let section = CropSection(cropAreaId: "1", name: "Test Section")
        
        BedMatrixView(beds: $beds, area: area, section: section, onBedSelected: { _ in })
            .environmentObject(FarmDataService.shared)
    }
}
