//
//  BedDetailView.swift
//  FarmiculturAPP
//
//  Comprehensive bed management interface
//

import SwiftUI

struct BedDetailView: View {
    @EnvironmentObject var farmService: FarmDataService
    @Binding var bed: Bed
    let area: CropArea
    let section: CropSection
    
    @State private var showingStatusChange = false
    @State private var showingPlantInfo = false
    @State private var showingHarvestReport = false
    @State private var showingFinishHarvest = false
    @State private var isUpdating = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            // Status Section
            Section(header: Text("Current Status")) {
                HStack {
                    Image(systemName: bed.status.icon)
                        .foregroundColor(bed.status.color)
                    Text(bed.status.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Circle()
                        .fill(bed.status.color)
                        .frame(width: 20, height: 20)
                }
                
                if let lastChange = bed.lastStatusChange {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last updated: \(lastChange.date, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let by = lastChange.changedBy {
                            Text("by \(by)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: { showingStatusChange = true }) {
                    Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Label("Delete Bed", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            // Bed Info
            Section(header: Text("Bed Information")) {
                LabeledContent("Bed Number", value: bed.bedNumber)
                LabeledContent("Area", value: area.name)
                LabeledContent("Section", value: section.name)
                
                if let datePlanted = bed.datePlanted {
                    LabeledContent("Date Planted", value: datePlanted, format: .dateTime.month().day().year())
                    if let days = bed.daysSincePlanted {
                        LabeledContent("Days Since Planted", value: "\(days) days")
                    }
                }
                
                if let startMethod = bed.startMethod {
                    HStack {
                        Text("Start Method")
                        Spacer()
                        Image(systemName: startMethod.icon)
                        Text(startMethod.displayName)
                    }
                }
            }
            
            // Plant Info
            if !bed.varieties.isEmpty || bed.status != .dirty {
                Section(header: Text("Plants")) {
                    if bed.varieties.isEmpty {
                        Button(action: { showingPlantInfo = true }) {
                            Label("Add Plant Information", systemImage: "plus.circle")
                        }
                    } else {
                        LabeledContent("Total Plants", value: "\(bed.totalPlantCount)")
                        
                        ForEach(bed.varieties) { variety in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(variety.name)
                                    .font(.headline)
                                HStack {
                                    Text("\(variety.count) plants")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let days = variety.daysToMaturity {
                                        Text("• \(days) days to maturity")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if variety.continuousHarvest {
                                        Text("• Continuous harvest")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Button(action: { showingPlantInfo = true }) {
                            Label("Edit Plants", systemImage: "pencil")
                        }
                    }
                    
                    if let expectedStart = bed.expectedHarvestStart {
                        LabeledContent("Expected Harvest", value: expectedStart, format: .dateTime.month().day().year())
                        if bed.isMultipleHarvest, let expectedEnd = bed.expectedHarvestEnd {
                            LabeledContent("Harvest Until", value: expectedEnd, format: .dateTime.month().day().year())
                        }
                    }
                }
            }
            
            // Harvest Section
            if bed.status == .harvesting || !bed.harvestReports.isEmpty {
                Section(header: Text("Harvest")) {
                    if bed.totalHarvested > 0 {
                        HStack {
                            Text("Total Harvested")
                                .font(.headline)
                            Spacer()
                            Text("\(bed.totalHarvested, specifier: "%.1f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            if let unit = bed.harvestReports.first?.unit {
                                Text(unit.shortName)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        LabeledContent("Number of Reports", value: "\(bed.harvestReports.count)")
                    }
                    
                    if bed.status == .harvesting {
                        Button(action: { showingHarvestReport = true }) {
                            Label("Report Harvest", systemImage: "basket.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { showingFinishHarvest = true }) {
                            Label("Finish Harvest", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Recent harvests
                if !bed.harvestReports.isEmpty {
                    Section(header: Text("Recent Harvests")) {
                        ForEach(bed.harvestReports.suffix(5).reversed()) { report in
                            HarvestReportRowView(report: report)
                        }
                    }
                }
            }
            
            // Status History
            if bed.statusHistory.count > 1 {
                Section(header: Text("Status History")) {
                    ForEach(bed.statusHistory.reversed()) { change in
                        StatusChangeRowView(change: change)
                    }
                }
            }
            
            // Notes
            Section(header: Text("Notes")) {
                if let notes = bed.notes {
                    Text(notes)
                } else {
                    Text("No notes")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("Bed \(bed.bedNumber)")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingStatusChange) {
            ChangeStatusView(bed: $bed, area: area, section: section)
        }
        .sheet(isPresented: $showingPlantInfo) {
            EditPlantInfoView(bed: $bed, area: area, section: section)
        }
        .sheet(isPresented: $showingHarvestReport) {
            HarvestReportView(bed: $bed, area: area, section: section)
        }
        .alert("Finish Harvest", isPresented: $showingFinishHarvest) {
            Button("Cancel", role: .cancel) {}
            Button("Finish & Archive", role: .destructive) {
                finishHarvest()
            }
        } message: {
            Text("This will archive the bed and reset it to Dirty status. Total harvested: \(bed.totalHarvested, specifier: "%.1f") from \(bed.harvestReports.count) reports.")
        }
        .alert("Delete Bed", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteBed()
            }
        } message: {
            Text("Are you sure you want to delete bed '\(bed.bedNumber)'? This will also delete all harvest history for this bed. This action cannot be undone.")
        }
    }
    
    func finishHarvest() {
        Task {
            do {
                try await farmService.archiveBed(bed, sectionId: section.id, areaId: area.id, finalNotes: nil)
                // Navigation will pop automatically
            } catch {
                print("Failed to archive bed: \(error)")
            }
        }
    }
    
    func deleteBed() {
        Task {
            do {
                try await farmService.deleteBed(bedId: bed.id, sectionId: section.id, areaId: area.id)
                // Navigation will pop automatically
            } catch {
                print("Failed to delete bed: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct StatusChangeRowView: View {
    let change: StatusChange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let from = change.fromStatus {
                    Text(from.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(change.toStatus.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Circle()
                    .fill(change.toStatus.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(change.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let by = change.changedBy {
                Text("by \(by)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = change.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

struct HarvestReportRowView: View {
    let report: HarvestReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(report.quantity, specifier: "%.1f") \(report.unit.shortName)")
                    .font(.headline)
                    .foregroundColor(.green)
                
                if let quality = report.quality {
                    Image(systemName: quality.icon)
                        .foregroundColor(quality.color)
                        .font(.caption)
                }
                
                Spacer()
                
                Text(report.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("by \(report.reportedBy)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !report.varieties.isEmpty {
                Text(report.varieties.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let notes = report.notes {
                Text(notes)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct BedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        @State var bed = Bed(
            sectionId: "section-1",
            cropAreaId: "area-1",
            bedNumber: "A1",
            status: .growing
        )
        
        let area = CropArea(farmId: "farm-1", name: "Greenhouse 1", type: .greenhouse)
        let section = CropSection(cropAreaId: "area-1", name: "Section A")
        
        NavigationView {
            BedDetailView(bed: $bed, area: area, section: section)
                .environmentObject(FarmDataService.shared)
        }
    }
}

