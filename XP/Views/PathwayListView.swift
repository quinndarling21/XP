import SwiftUI

struct PathwayCard: View {
    @ObservedObject var pathway: Pathway
    
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
                
                if let activeCycle = pathway.activeCadenceCycle,
                   activeCycle.currentStreak > 0 {
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(pathway.pathwayColor)
                .shadow(radius: 5)
        )
    }
}

struct PathwayListView: View {
    @StateObject private var viewModel = PathwayViewModel()
    @State private var showingAddPathway = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                #if DEBUG
                DebugTimeView()
                #endif
                
                // App Title
                Text("XP")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.pathways, id: \.id) { pathway in
                            NavigationLink(destination: ContentView(pathwayId: pathway.id ?? UUID())) {
                                PathwayCard(pathway: pathway)
                            }
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
                        showingAddPathway = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingAddPathway) {
                AddPathwayView(viewModel: viewModel)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                viewModel.refreshPathways()
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
