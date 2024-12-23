import SwiftUI

struct EditCadenceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var pathway: Pathway
    @EnvironmentObject var mainViewModel: MainViewModel
    
    @State private var frequency: CadenceFrequency
    @State private var count: Int
    @State private var applyImmediately = true
    
    init(pathway: Pathway) {
        self.pathway = pathway
        _frequency = State(initialValue: pathway.activeCadenceCycle?.cadenceFrequency ?? .none)
        _count = State(initialValue: Int(pathway.activeCadenceCycle?.count ?? 3))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    CadenceSettingsView(
                        frequency: $frequency,
                        count: $count
                    )
                }
                
                if pathway.activeCadenceCycle != nil {
                    Section {
                        Toggle("Apply Changes Immediately", isOn: $applyImmediately)
                        
                        if !applyImmediately {
                            Text("Changes will take effect at the next cycle reset")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Edit Cadence")
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
    
    private func saveChanges() {
        if frequency == .none {
            pathway.disableCadence()
        } else {
            pathway.updateCadence(
                frequency: frequency,
                count: count,
                applyImmediately: applyImmediately
            )
        }
        dismiss()
    }
} 