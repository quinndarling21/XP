import SwiftUI

struct ObjectiveDetailView: View {
    let objective: Objective
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Circle()
                .fill(objective.isCompleted ? .green : .blue)
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: objective.isCompleted ? "checkmark" : "star.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            
            // XP Value
            VStack(spacing: 8) {
                Text("Reward")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("\(objective.xpValue) XP")
                    .font(.system(size: 36, weight: .bold))
            }
            
            if !objective.isCompleted {
                Button {
                    onComplete()
                    dismiss()
                } label: {
                    Text("Mark as Complete")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("ObjectiveDetailView")
    }
}

#Preview {
    ObjectiveDetailView(
        objective: Objective(
            id: UUID(),
            xpValue: 250,
            isCompleted: false,
            order: 0
        ),
        onComplete: {}
    )
} 