import SwiftUI

struct PathwayCard: View {
    @ObservedObject var pathway: Pathway
    
    private var needsAttention: Bool {
        guard let activeCycle = pathway.activeCadenceCycle else { return false }
        return activeCycle.completedObjectivesCount < Int(activeCycle.count)
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
    
    var body: some View {
        ZStack {
            // Background glow layer
            if needsAttention {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.red)
                    .blur(radius: 8)
                    .opacity(0.9)
            }
            
            // Card content layer
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pathway.name ?? "Unnamed Pathway")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Level \(pathway.currentLevel)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()

                    if let activeCycle = pathway.activeCadenceCycle {
                        VStack(alignment: .trailing, spacing: 4) {
                            // Cadence Progress
                            Text("\(min(activeCycle.completedObjectivesCount, Int(activeCycle.count)))/\(activeCycle.count)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                            
                            // Streak (if exists)
                            if activeCycle.currentStreak > 0 {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(.orange)
                                    Text("\(activeCycle.currentStreak) \(streakText(for: activeCycle))")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(pathway.pathwayColor)
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 5
                    )
            )
        }
        .animation(.easeInOut, value: needsAttention)
    }
}

struct PathwayListView: View {
    @StateObject private var viewModel = PathwayViewModel()
    @State private var showingAddPathway = false
    @State private var showingSettings = false
    @State private var currentGreeting: String = ""
    @Environment(\.scenePhase) private var scenePhase
    
    private func randomMotivationalPhrase() -> String {
        let phrases = [
            "Ready for another epic day? 🚀",
            "Let's make today count! ⭐️",
            "Your journey continues... 🎯",
            "Small steps, big victories! 💪",
            "Keep that momentum going! 🔥",
            "You're on a roll! 🎲",
            "Adventure awaits! 🗺️",
            "Making progress look good! ✨"
        ]
        return phrases.randomElement() ?? phrases[0]
    }
    
    private func randomGreeting(for name: String) -> String {
        let greetings = [
            "Hey \(name)",
            "Yo \(name)",
            "What's up \(name)",
            "Howdy \(name)",
            "Hi there \(name)",
            "Welcome back \(name)",
            "Sup \(name)",
            "G'day \(name)",
            "Hiya \(name)",
            "Ahoy \(name)",
            "Aloha \(name)",
            "*fist bump* \(name)",
            "Look who's here! \(name)",
            "The legend returns! \(name)",
            "Ready player \(name)",
            "Power up, \(name)",
            "⚡️ \(name) has entered the chat",
            "Mission control to \(name)",
            "Player 1: \(name)",
            "Loading awesome... \(name)"
        ]
        return greetings.randomElement() ?? greetings[0]
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                #if DEBUG
                DebugTimeView()
                #endif
                
                // App Title Section
                VStack(spacing: 8) {
                    if let firstName = viewModel.user?.firstName, !firstName.isEmpty {
                        Text(currentGreeting)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 2)
                            .onAppear {
                                currentGreeting = randomGreeting(for: firstName)
                            }
                    }
                    
                    Text("Time to level up!")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 3)
                        .padding(.bottom, 4)
                    
                    // Optional: Add a fun motivational subtitle that changes randomly
                    Text(randomMotivationalPhrase())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.pathways, id: \.id) { pathway in
                            NavigationLink(destination: ContentView(pathwayId: pathway.id ?? UUID())) {
                                PathwayCard(pathway: pathway)
                            }
                        }
                        
                        // Add New Pathway Button
                        Button(action: {
                            showingAddPathway = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New Pathway")
                            }
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                                    .background(Color.accentColor.opacity(0.1))
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                
                if let user = viewModel.user {
                    XPProgressBar(
                        currentXP: user.currentXP,
                        requiredXP: user.requiredXPForLevel,
                        level: user.currentLevel,
                        tintColor: .blue
                    )
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingAddPathway) {
                AddPathwayView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                viewModel.refreshPathways()
                if let firstName = viewModel.user?.firstName, !firstName.isEmpty {
                    currentGreeting = randomGreeting(for: firstName)
                }
            }
        }
        .onAppear {
            viewModel.fetchUserData()
            viewModel.refreshPathways()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserXPDidChange"))) { _ in
            viewModel.fetchUserData()
            viewModel.refreshPathways()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PathwayDidUpdate"))) { _ in
            viewModel.refreshPathways()
        }
    }
} 
