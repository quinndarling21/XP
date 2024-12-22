import SwiftUI

struct AddPathwayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PathwayViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColorIndex = 0
    
    let colorOptions: [(name: String, color: Color)] = [
        ("Red", .flame),
        ("Blue", .delftBlue),
        ("Orange", .orangeWeb),
        ("Green", .olivine),
        ("Blue", .airSuperiorityBlue)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pathway Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Color Theme")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<colorOptions.count, id: \.self) { index in
                                Circle()
                                    .fill(colorOptions[index].color)
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        if index == selectedColorIndex {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 3)
                                                .padding(2)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColorIndex = index
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Add Pathway")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addPathway(
                            name: name,
                            description: description,
                            colorIndex: selectedColorIndex
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 