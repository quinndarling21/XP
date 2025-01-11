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
                    // Enhanced Title Section
                    VStack(spacing: 8) {
                        Text(pathway.name ?? "Unnamed Pathway")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2)
                            .padding(.top, 16)
                        
                        if let activeCycle = pathway.activeCadenceCycle,
                           activeCycle.currentStreak > 0 {
                            HStack(spacing: 8) {
                                // Streak Icon with more contrast
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.3))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.orange, .yellow.opacity(0.9)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 1)
                                }
                                
                                // Streak Text with better contrast
                                Text("\(activeCycle.currentStreak) \(streakText(for: activeCycle))")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 1)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        pathway.pathwayColor,
                                        pathway.pathwayColor.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.2)
                    )
                    
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
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .background(
                            Circle()
                                .fill(.black.opacity(0.2))
                                .frame(width: 32, height: 32)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 1)
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

struct PulsingCircle: View {
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .opacity(isAnimating ? 0 : 0.8)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct ObjectiveNode: View {
    let objective: Objective
    let isCurrentTask: Bool
    let pathwayColor: Color
    let onComplete: () -> Void
    
    @State private var showingDetail = false
    @State private var animateCompletion = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            VStack(spacing: 12) {
                // Main Circle
                ZStack {
                    // Pulsing circles for current task
                    if isCurrentTask {
                        PulsingCircle(color: pathwayColor)
                            .frame(width: 90, height: 90)
                        PulsingCircle(color: pathwayColor)
                            .frame(width: 90, height: 90)
                            .opacity(0.5)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(0.5),
                                value: true
                            )
                    }
                    
                    // Background Circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: nodeGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isCurrentTask ? 90 : 80, height: isCurrentTask ? 90 : 80)
                        .shadow(
                            color: nodeColor.opacity(0.4),
                            radius: isCurrentTask ? 12 : 5,
                            y: 3
                        )
                        .overlay {
                            if isCurrentTask {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                pathwayColor.opacity(0.8),
                                                pathwayColor.opacity(0.4)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 3
                                    )
                            }
                        }
                    
                    // Icon
                    if objective.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1)
                            .rotationEffect(.degrees(animateCompletion ? 0 : -90))
                            .opacity(animateCompletion ? 1 : 0)
                            .onAppear {
                                withAnimation(.spring(duration: 0.5)) {
                                    animateCompletion = true
                                }
                            }
                    } else if isCurrentTask {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 18, weight: .bold))
                                .offset(y: -2)
                            Text("START")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1)
                        .scaleEffect(1.1)
                        .offset(y: 2)
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .overlay {
                    if objective.isInCurrentCycle {
                        Circle()
                            .stroke(pathwayColor, lineWidth: 3)
                            .shadow(
                                color: pathwayColor.opacity(0.6),
                                radius: glowRadius
                            )
                    }
                }
                
                // XP Value
                Text("\(objective.xpValue) XP")
                    .font(.system(size: isCurrentTask ? 16 : 14, weight: .medium))
                    .foregroundStyle(xpTextColor)
                    .shadow(color: .black.opacity(0.1), radius: 1)
            }
            .scaleEffect(isCurrentTask ? 1.1 : 1.0)
            .animation(.spring(duration: 0.3), value: isCurrentTask)
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
        objective.isInCurrentCycle ? 12 : 0
    }
    
    private var nodeColor: Color {
        if objective.isCompleted {
            return .green
        }
        return isCurrentTask ? pathwayColor : .gray
    }
    
    private var nodeGradientColors: [Color] {
        if objective.isCompleted {
            return [.green, .green.opacity(0.9)]
        }
        return isCurrentTask ? 
            [pathwayColor, pathwayColor.opacity(0.9)] : 
            [.gray.opacity(0.6), .gray.opacity(0.8)]
    }
    
    private var xpTextColor: Color {
        if objective.isCompleted {
            return .green
        }
        return isCurrentTask ? pathwayColor : .gray
    }
}

struct XPProgressBar: View {
    let currentXP: Int32
    let requiredXP: Int32
    let level: Int32
    let tintColor: Color
    
    @State private var isAnimating = false
    @State private var showingSparkles = false
    
    private var progress: Double {
        Double(currentXP) / Double(requiredXP)
    }
    
    private var formattedProgress: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter.string(from: NSNumber(value: progress)) ?? "0%"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Level Badge and XP Counter
            HStack {
                // Level Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor, tintColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: tintColor.opacity(0.3), radius: 4)
                    
                    VStack(spacing: -2) {
                        Text("Level")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(level)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                    }
                    .shadow(radius: 1)
                }
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .opacity(0.3)
                }
                
                Spacer()
                
                // XP Counter
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentXP)")
                        .font(.system(size: 24, weight: .bold))
                    Text("/")
                        .font(.system(size: 16, weight: .medium))
                        .opacity(0.7)
                    Text("\(requiredXP)")
                        .font(.system(size: 16, weight: .medium))
                        .opacity(0.7)
                    Text("XP")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.leading, 2)
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [tintColor, tintColor.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            // Progress Bar
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 24)
                
                // Progress Fill
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [tintColor, tintColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isAnimating ? UIScreen.main.bounds.width * CGFloat(progress) : 0, height: 24)
                    .overlay {
                        // Shimmer effect
                        if isAnimating {
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0),
                                                .white.opacity(0.5),
                                                .white.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 20)
                                    .offset(x: -10 + (geometry.size.width * (isAnimating ? 1 : 0)))
                                    .blur(radius: 3)
                            }
                        }
                    }
                    .animation(.spring(duration: 1.0), value: isAnimating)
                
                // Percentage Text
                Text(formattedProgress)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .shadow(radius: 1)
            }
            
            // Level Up Sparkles
            if showingSparkles {
                HStack(spacing: 2) {
                    ForEach(0..<3) { index in
                        Image(systemName: "sparkle")
                            .font(.system(size: 14))
                            .foregroundColor(tintColor)
                            .opacity(showingSparkles ? 1 : 0)
                            .scaleEffect(showingSparkles ? 1.2 : 0.8)
                            .animation(
                                .spring(duration: 0.5)
                                .repeatCount(3)
                                .delay(Double(index) * 0.1),
                                value: showingSparkles
                            )
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .onAppear {
            withAnimation {
                isAnimating = true
            }
            // Show sparkles if close to leveling up
            if progress > 0.9 {
                withAnimation {
                    showingSparkles = true
                }
            }
        }
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
