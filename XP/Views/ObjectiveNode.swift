struct ObjectiveNode: View {
    let objective: Objective
    let isCurrentTask: Bool
    let pathwayColor: Color
    let onComplete: () -> Void
    
    @State private var showingDetail = false
    
    private var glowRadius: CGFloat {
        objective.isInCurrentCycle ? 10 : 0
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
    
    private var nodeColor: LinearGradient {
        if objective.isCompleted {
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        }
        return isCurrentTask ? 
            LinearGradient(colors: [pathwayColor, pathwayColor.opacity(0.8)], startPoint: .top, endPoint: .bottom) : 
            LinearGradient(colors: [.gray.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom)
    }
} 