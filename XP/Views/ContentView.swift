import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 0) {
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
    
    var nodeColor: LinearGradient {
        if objective.isCompleted {
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        }
        return isCurrentTask ? LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom)
    }
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(nodeColor)
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    .overlay {
                        if objective.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.title)
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
                    .font(.caption2)
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
