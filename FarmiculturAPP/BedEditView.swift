import SwiftUI

struct BedEditView: View {
    let sectionIndex: Int
    let bedIndex: Int
    @Binding var crop: Crop
    
    @State private var plantsCountText: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Bed Info")) {
                Text("Section \(sectionIndex + 1), Bed \(bedIndex + 1)")
                
                TextField("Number of plants", text: $plantsCountText)
                    .keyboardType(.numberPad)
            }
            
            Button("Save") {
                if let newCount = Int(plantsCountText) {
                    crop.sections[sectionIndex][bedIndex].plantCount = newCount
                }
            }
        }
        .navigationTitle("Edit Bed")
        .onAppear {
            // Populate the text field with existing value
            plantsCountText = "\(crop.sections[sectionIndex][bedIndex].plantCount)"
        }
    }
}
