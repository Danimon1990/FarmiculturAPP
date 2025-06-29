import SwiftUI

struct LandMapPrototype: View {
    @State private var rows: Int = 6
    @State private var columns: Int = 8
    @State private var selected: Set<GridPosition> = []
    
    var body: some View {
        VStack {
            Text("Land Map Prototype")
                .font(.title)
                .padding(.bottom)
            
            // Controls for grid size
            HStack {
                Stepper("Rows: \(rows)", value: $rows, in: 1...12)
                Stepper("Columns: \(columns)", value: $columns, in: 1...16)
            }
            .padding(.bottom)
            
            // The grid
            GeometryReader { geometry in
                let boxSize = min(geometry.size.width / CGFloat(columns), geometry.size.height / CGFloat(rows))
                VStack(spacing: 4) {
                    ForEach(0..<rows, id: \..self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \..self) { col in
                                let pos = GridPosition(row: row, col: col)
                                Rectangle()
                                    .fill(selected.contains(pos) ? Color.blue.opacity(0.6) : Color.gray.opacity(0.2))
                                    .frame(width: boxSize, height: boxSize)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        if selected.contains(pos) {
                                            selected.remove(pos)
                                        } else {
                                            selected.insert(pos)
                                        }
                                    }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1.3, contentMode: .fit)
            .padding()
            
            Text("Tap boxes to select/deselect. Adjust grid size above.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .padding()
    }
}

struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

struct LandMapPrototype_Previews: PreviewProvider {
    static var previews: some View {
        LandMapPrototype()
    }
} 