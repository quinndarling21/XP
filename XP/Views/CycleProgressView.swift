import SwiftUI

struct CycleProgressView: View {
    @ObservedObject var pathway: Pathway
    @ObservedObject var cycle: CadenceCycle
    
    private var completedCount: Int {
        cycle.completedObjectivesCount
    }
    
    private var totalCount: Int {
        Int(cycle.count)
    }
    
    private var timeframeText: String {
        switch cycle.cadenceFrequency {
        case .daily: return "today"
        case .weekly: return "this week"
        case .monthly: return "this month"
        case .none: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress text (removed streak, keeping only completion status)
            Text("\(completedCount) of \(totalCount) completed \(timeframeText)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(pathway.pathwayColor.opacity(0.2))
                    
                    // Progress
                    if completedCount > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(pathway.pathwayColor)
                            .frame(width: geometry.size.width * CGFloat(completedCount) / CGFloat(totalCount))
                            .animation(.spring, value: completedCount)
                    }
                }
            }
            .frame(height: 8)
            
            // Time until reset (if close)
            if let timeUntil = cycle.timeUntilReset, timeUntil < 86400 { // 24 hours
                Text(timeUntilResetText(timeUntil))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private func timeUntilResetText(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "Resets in \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = Int(timeInterval / 3600)
            return "Resets in \(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
} 