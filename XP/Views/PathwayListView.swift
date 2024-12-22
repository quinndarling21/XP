import SwiftUI

struct PathwayListView: View {
    @StateObject private var viewModel = PathwayViewModel()
    @State private var showingAddPathway = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.pathways, id: \.id) { pathway in
                        NavigationLink(destination: ContentView(pathway: pathway)) {
                            HStack {
                                Circle()
                                    .fill(pathway.pathwayColor)
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading) {
                                    Text(pathway.name ?? "Unnamed Pathway")
                                        .font(.headline)
                                    Text(pathway.descriptionText ?? "No description")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.removePathway(viewModel.pathways[index])
                        }
                    }
                }
                
                if let user = viewModel.user {
                    XPProgressBar(
                        currentXP: user.currentXP,
                        requiredXP: user.requiredXPForLevel,
                        level: user.currentLevel
                    )
                    .padding()
                }
            }
            .navigationTitle("Pathways")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddPathway = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPathway) {
                AddPathwayView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.fetchUserData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserXPDidChange"))) { _ in
                viewModel.fetchUserData()
            }
        }
    }
} 
