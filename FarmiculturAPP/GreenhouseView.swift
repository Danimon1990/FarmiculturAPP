//
//  GreenhouseView.swift
//  FarmiculturAPP
//
//  Created by Daniel Moreno on 11/3/24.
//
import SwiftUI

struct BedView: View {
    let bed: Bed
    let sectionIndex: Int
    let bedIndex: Int
    @Binding var crop: Crop
    
    var body: some View {
        NavigationLink(destination: BedEditView(
            sectionIndex: sectionIndex,
            bedIndex: bedIndex,
            crop: $crop
        )) {
            VStack(spacing: 2) {
                Text("\(bed.totalPlants)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(height: 30)
                
                if !bed.varieties.isEmpty {
                    Text("\(bed.varieties.count) varieties")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("Empty")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(bed.state.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(bed.totalPlants > 0 ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            )
        }
    }
}

struct SectionView: View {
    let sectionIndex: Int
    let section: [Bed]
    @Binding var crop: Crop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Section \(sectionIndex + 1)")
                .font(.headline)
                .padding(.leading)
            
            HStack(spacing: 10) {
                ForEach(section.indices, id: \.self) { bedIndex in
                    BedView(
                        bed: section[bedIndex],
                        sectionIndex: sectionIndex,
                        bedIndex: bedIndex,
                        crop: $crop
                    )
                }
            }
        }
    }
}

struct GreenhouseView: View {
    @Binding var crop: Crop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details for \(crop.name)")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(crop.sections.indices, id: \.self) { sectionIndex in
                        SectionView(
                            sectionIndex: sectionIndex,
                            section: crop.sections[sectionIndex],
                            crop: $crop
                        )
                    }
                }
            }
        }
        .navigationTitle("\(crop.name) Layout")
    }
}
