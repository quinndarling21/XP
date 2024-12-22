import SwiftUI

struct AddPathwayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PathwayViewModel
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pathway Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
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
                        viewModel.addPathway(name: name, description: description)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 