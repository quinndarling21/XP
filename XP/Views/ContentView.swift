import SwiftUI
import CoreData

struct ContentView: View {
    let pathwayId: UUID
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var pathway: Pathway?
    
    var body: some View {
        VStack(spacing: 0) {
            if let pathway = pathway {
                // Title Section
                Text(pathway.name ?? "Unnamed Pathway")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(pathway.pathwayColor)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.objectives(for: pathway)) { objective in
                                ObjectiveNode(
                                    objective: objective,
                                    isCurrentTask: objective.order == Int(pathway.objectivesCompleted),
                                    onComplete: {
                                        viewModel.markObjectiveComplete(objective, in: pathway)
                                        refreshPathway()
                                    },
                                    pathwayColor: pathway.pathwayColor
                                )
                                .id(objective.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        if let currentObjective = viewModel.objectives(for: pathway).first(where: { $0.order == Int(pathway.objectivesCompleted) }) {
                            proxy.scrollTo(currentObjective.id, anchor: .top)
                        }
                    }
                }
                
                XPProgressBar(
                    currentXP: pathway.currentXP,
                    requiredXP: pathway.requiredXPForLevel,
                    level: pathway.currentLevel,
                    tintColor: pathway.pathwayColor
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        dismiss()
                        if let pathway = pathway {
                            viewModel.deletePathway(pathway)
                        }
                    } label: {
                        Label("Delete Pathway", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            refreshPathway()
        }
    }
    
    private func refreshPathway() {
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        request.predicate = NSPredicate(format: "id == %@", pathwayId as CVarArg)
        
        do {
            let pathways = try viewContext.fetch(request)
            pathway = pathways.first
        } catch {
            print("Error fetching pathway: \(error)")
        }
    }
}

struct ObjectiveNode: View {
    let objective: Objective
    let isCurrentTask: Bool
    let onComplete: () -> Void
    let pathwayColor: Color
    @State private var showingDetail = false
    
    var nodeColor: LinearGradient {
        if objective.isCompleted {
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        }
        return isCurrentTask ? 
            LinearGradient(colors: [pathwayColor, pathwayColor.opacity(0.8)], startPoint: .top, endPoint: .bottom) : 
            LinearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom)
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
                onComplete: onComplete,
                pathwayColor: pathwayColor
            )
        }
    }
}

struct XPProgressBar: View {
    let currentXP: Int32
    let requiredXP: Int32
    let level: Int32
    let tintColor: Color
    
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
                .tint(tintColor)
        }
        .padding()
        .background(tintColor.opacity(0.1))
    }
}

#Preview {
    // Create a sample Pathway for preview
    let context = PersistenceController(inMemory: true).container.viewContext
    let samplePathway = Pathway(context: context)
    samplePathway.name = "Sample Pathway"
    samplePathway.descriptionText = "A sample pathway for testing."
    samplePathway.id = UUID() // Ensure ID is set
    
    try? context.save() // Save to ensure ID is persisted
    
    return ContentView(pathwayId: samplePathway.id!)
        .environment(\.managedObjectContext, context)
} 
