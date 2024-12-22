import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.objectives) { objective in
                            ObjectiveNode(
                                objective: objective,
                                isCurrentTask: objective.order == Int(viewModel.user?.objectivesCompleted ?? 0)
                            ) {
                                viewModel.markObjectiveComplete(objective)
                            }
                            .id(objective.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let currentObjective = viewModel.objectives.first(where: { $0.order == Int(viewModel.user?.objectivesCompleted ?? 0) }) {
                        proxy.scrollTo(currentObjective.id, anchor: .top)
                    }
                }
            }
            
            Spacer()
            
            XPProgressBar(
                currentXP: viewModel.user?.currentXP ?? 0,
                requiredXP: viewModel.user?.requiredXPForLevel ?? 1000,
                level: viewModel.user?.currentLevel ?? 1
            )
        }
    }
}

struct ObjectiveNode: View {
    let objective: Objective
    let isCurrentTask: Bool
    let onComplete: () -> Void
    @State private var showingDetail = false
    
    var nodeColor: Color {
        if objective.isCompleted {
            return .green
        }
        return isCurrentTask ? .blue : .gray.opacity(0.5)
    }
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 60, height: 60)
                    .overlay {
                        if objective.isCompleted {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.white)
                        } else if isCurrentTask {
                            Text("START")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        } else {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                
                Text("\(objective.xpValue) XP")
                    .font(.caption)
                    .foregroundStyle(objective.isCompleted || isCurrentTask ? .primary : .secondary)
            }
        }
        .disabled(!isCurrentTask && !objective.isCompleted)
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
