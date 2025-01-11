import SwiftUI

struct PathwayCard: View {
    @ObservedObject var pathway: Pathway
    
    private var needsAttention: Bool {
        guard let activeCycle = pathway.activeCadenceCycle else { return false }
        return activeCycle.completedObjectivesCount < Int(activeCycle.count)
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
            VStack(alignment: .leading, spacing: 8) {
                // Title and Level
                VStack(alignment: .leading, spacing: 4) {
                    Text(pathway.name ?? "Unnamed Pathway")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Level \(pathway.currentLevel)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Progress and Streak
                if let activeCycle = pathway.activeCadenceCycle {
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress
                        HStack {
                            Text("\(min(activeCycle.completedObjectivesCount, Int(activeCycle.count)))/\(activeCycle.count)")
                                .font(.system(size: 14, weight: .medium))
                            
                            if activeCycle.currentStreak > 0 {
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("\(activeCycle.currentStreak)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .padding(12)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
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
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
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
                VStack(spacing: 4) {
                    // User greeting - now centered
                    Text("Sup \(viewModel.user?.firstName ?? "Friend")")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Level up text - centered
                    Text("Time to level up!")
                        .font(.system(size: min(UIScreen.main.bounds.width * 0.08, 32), weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    
                    // Subtitle - centered
                    Text("Keep that momentum going! 💪")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.pathways, id: \.id) { pathway in
                            NavigationLink(destination: ContentView(pathwayId: pathway.id ?? UUID())) {
                                PathwayCard(pathway: pathway)
                            }
                        }
                        
                        // Add New Pathway Button
                        Button(action: {
                            showingAddPathway = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                Text("New Pathway")
                                    .font(.callout.bold())
                            }
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120) // Match height of other cards
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.accentColor, lineWidth: 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(16)
                            )
                        }
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
