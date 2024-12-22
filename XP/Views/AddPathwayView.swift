import SwiftUI

struct AddPathwayView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PathwayViewModel
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColorIndex = 0
    @State private var cadenceFrequency: CadenceFrequency = .none
    @State private var objectiveCount = 3
    
    private var isValid: Bool {
        !name.isEmpty && 
        !description.isEmpty && 
        (cadenceFrequency == .none || (objectiveCount >= 1 && objectiveCount <= 50))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pathway Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Appearance")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<Pathway.pathwayColors.count, id: \.self) { index in
                                Circle()
                                    .fill(Pathway.pathwayColors[index])
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
                
                Section {
                    CadenceSettingsView(
                        frequency: $cadenceFrequency,
                        count: $objectiveCount
                    )
                }
                
                Section {
                    Button("Create Pathway") {
                        viewModel.addPathway(
                            name: name,
                            description: description,
                            colorIndex: selectedColorIndex,
                            cadenceFrequency: cadenceFrequency,
                            objectivesCount: objectiveCount
                        )
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid)
                }
            }
            .navigationTitle("New Pathway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview provider
struct AddPathwayView_Previews: PreviewProvider {
    static var previews: some View {
        AddPathwayView(viewModel: PathwayViewModel())
    }
} 