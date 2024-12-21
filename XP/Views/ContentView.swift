import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 20) {
            // Objectives List
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150, maximum: 200))
                ], spacing: 16) {
                    ForEach(viewModel.objectives) { objective in
                        ObjectiveCard(objective: objective) {
                            viewModel.markObjectiveComplete(objective)
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // XP Progress Bar
            XPProgressBar(
                currentXP: viewModel.user?.currentXP ?? 0,
                requiredXP: viewModel.user?.requiredXPForLevel ?? 1000,
                level: viewModel.user?.currentLevel ?? 1
            )
        }
    }
}

// MARK: - Supporting Views

struct ObjectiveCard: View {
    let objective: Objective
    let onComplete: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 12) {
                Circle()
                    .fill(objective.isCompleted ? .green : .blue)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: objective.isCompleted ? "checkmark" : "star.fill")
                            .foregroundStyle(.white)
                    }
                
                Text("\(objective.xpValue) XP")
                    .font(.headline)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background)
                    .shadow(radius: 2)
            )
        }
        .accessibilityIdentifier("objective-card")
        .sheet(isPresented: $showingDetail) {
            ObjectiveDetailView(
                objective: objective,
                onComplete: onComplete
            )
        }
    }
}

struct XPProgressBar: View {
    let currentXP: Int32
    let requiredXP: Int32
    let level: Int32
    
    private var progress: Double {
        Double(currentXP) / Double(requiredXP)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(.headline)
                Spacer()
                Text("\(currentXP)/\(requiredXP) XP")
                    .font(.subheadline)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
        }
        .padding()
        .background(.bar)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
} 
