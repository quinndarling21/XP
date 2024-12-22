import SwiftUI

struct CadenceSettingsView: View {
    @Binding var frequency: CadenceFrequency
    @Binding var count: Int
    
    private let countRange = 1...50
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cadence Settings")
                .font(.headline)
            
            // Frequency Picker
            Picker("Timeframe", selection: $frequency) {
                ForEach(CadenceFrequency.allCases, id: \.self) { freq in
                    Text(freq.description)
                        .tag(freq)
                }
            }
            .pickerStyle(.segmented)
            
            if frequency != .none {
                // Objective Count Stepper
                HStack {
                    Text("Objectives per \(frequency.description.lowercased())")
                    Spacer()
                    Stepper("\(count)", value: $count, in: countRange)
                        .fixedSize()
                }
                
                // Count Slider for quick adjustment
                Slider(
                    value: Binding(
                        get: { Double(count) },
                        set: { count = Int($0) }
                    ),
                    in: Double(countRange.lowerBound)...Double(countRange.upperBound),
                    step: 1
                )
                
                // Helper text
                Text("Complete \(count) objective\(count == 1 ? "" : "s") \(frequency.description.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
    }
}