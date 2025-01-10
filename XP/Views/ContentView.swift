import SwiftUI
import CoreData

struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct ViewPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var speed: Double
}

struct ParticleSystem: View {
    let color: Color
    let maxHeight: CGFloat
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.position.x,
                        y: particle.position.y,
                        width: 4 * particle.scale,
                        height: 4 * particle.scale
                    )
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                updateParticles()
            }
            .onAppear {
                // Initialize particles
                for _ in 0..<50 {
                    createParticle()
                }
            }
        }
    }
    
    private func createParticle() {
        let particle = Particle(
            position: CGPoint(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: maxHeight...UIScreen.main.bounds.height)
            ),
            scale: CGFloat.random(in: 0.5...1.5),
            opacity: Double.random(in: 0.2...0.7),
            speed: Double.random(in: 0.5...2)
        )
        particles.append(particle)
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].position.y -= particles[i].speed
            
            // Reset particle if it goes above maxHeight
            if particles[i].position.y < maxHeight {
                particles[i].position.y = UIScreen.main.bounds.height
                particles[i].position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            }
        }
    }
}

struct ContentView: View {
    let pathwayId: UUID
    @StateObject private var viewModel = MainViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var pathway: Pathway?
    @State private var startButtonPosition: CGFloat = 0
    @State private var scrollOffset: CGPoint = .zero
    @State private var showingCadenceEdit = false
    
    private func calculateProgress(objectives: [Objective]) -> Double {
        let totalCount = Double(objectives.count)
        let completedCount = Double(objectives.filter { $0.isCompleted }.count)
        return completedCount / totalCount
    }
    
    private func calculateFillHeight(geometry: GeometryProxy, objectives: [Objective]) -> CGFloat {
        let totalHeight = geometry.size.height
        if let currentObjective = objectives.first(where: { !$0.isCompleted }) {
            let index = objectives.firstIndex(where: { $0.id == currentObjective.id }) ?? 0
            let spacing: CGFloat = 24  // Match your LazyVStack spacing
            let objectiveHeight: CGFloat = 90  // Approximate height of ObjectiveNode
            let topPadding: CGFloat = 44 + 36  // Navigation bar + title padding
            
            return topPadding + (objectiveHeight + spacing) * CGFloat(index)
        }
        return totalHeight
    }
    
    var body: some View {
        ZStack {
            // Particle Background
            if let pathway = pathway {
                ParticleSystem(
                    color: pathway.pathwayColor,
                    maxHeight: startButtonPosition
                )
                .opacity(0.3)
            }
            
            // Main Content
            VStack(spacing: 0) {
                if let pathway = pathway {
                    // Title Section with Streak
                    VStack(spacing: 4) {
                        Text(pathway.name ?? "Unnamed Pathway")
                            .font(.system(size: 36, weight: .bold))
                        
                        if let activeCycle = pathway.activeCadenceCycle, activeCycle.currentStreak > 0 {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("\(activeCycle.currentStreak) \(streakText(for: activeCycle))")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(pathway.pathwayColor)
                    
                    // Cycle Progress (if active)
                    if let activeCycle = pathway.activeCadenceCycle {
                        CycleProgressView(pathway: pathway, cycle: activeCycle)
                            .padding(.vertical)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(viewModel.objectives(for: pathway)) { objective in
                                    ObjectiveNode(
                                        objective: objective,
                                        isCurrentTask: !objective.isCompleted && viewModel.objectives(for: pathway)
                                            .filter { !$0.isCompleted }
                                            .first?.id == objective.id,
                                        pathwayColor: pathway.pathwayColor,
                                        onComplete: {
                                            viewModel.markObjectiveComplete(objective, in: pathway)
                                            refreshPathway()
                                        }
                                    )
                                    .id(objective.id)
                                }
                            }
                            .padding()
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingCadenceEdit = true
                    } label: {
                        Label("Edit Cadence", systemImage: "clock")
                    }
                    
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
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            refreshPathway()
            setupAppearance()
            
            // Add observer for pathway updates
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("PathwayDidUpdate"),
                object: nil,
                queue: .main
            ) { _ in
                refreshPathway()
            }
        }
        .sheet(isPresented: $showingCadenceEdit) {
            if let pathway = pathway {
                EditCadenceView(pathway: pathway)
                    .environmentObject(viewModel)
            }
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
    
    private func streakText(for cycle: CadenceCycle) -> String {
        let count = cycle.currentStreak
        switch cycle.cadenceFrequency {
        case .daily:
            return "day\(count == 1 ? "" : "s")"
        case .weekly:
            return "week\(count == 1 ? "" : "s")"
        case .monthly:
            return "month\(count == 1 ? "" : "s")"
        case .none:
            return ""
        }
    }
    
    private func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
}

struct ObjectiveNode: View {
    let objective: Objective
    let isCurrentTask: Bool
    let pathwayColor: Color
    let onComplete: () -> Void
    
    @State private var showingDetail = false
    
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
                    .overlay {
                        if objective.isInCurrentCycle {
                            Circle()
                                .stroke(pathwayColor, lineWidth: 2)
                                .shadow(color: pathwayColor.opacity(0.5), radius: glowRadius)
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
    
    private var glowRadius: CGFloat {
        objective.isInCurrentCycle ? 10 : 0
    }
    
    private var nodeColor: LinearGradient {
        if objective.isCompleted {
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        }
        return isCurrentTask ? 
            LinearGradient(colors: [pathwayColor, pathwayColor.opacity(0.8)], startPoint: .top, endPoint: .bottom) : 
            LinearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom)
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
    
    return ContentView(pathwayId: UUID())
        .environment(\.managedObjectContext, context)
} 
