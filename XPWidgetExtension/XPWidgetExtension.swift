//
//  XPWidgetExtension.swift
//  XPWidgetExtension
//
//  Created by Quinn Darling on 1/11/25.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - Pathway Info
struct PathwayInfo {
    let emoji: String
    let needsAttention: Bool
}

// MARK: - Timeline Entry
struct PathwayWidgetEntry: TimelineEntry {
    let date: Date
    let pathways: [PathwayInfo]
}

// MARK: - Timeline Provider
struct PathwayProvider: TimelineProvider {
    let persistenceController: PersistenceController
    
    init() {
        persistenceController = PersistenceController.shared
    }
    
    func placeholder(in context: Context) -> PathwayWidgetEntry {
        PathwayWidgetEntry(date: Date(), pathways: [
            PathwayInfo(emoji: "✨", needsAttention: true),
            PathwayInfo(emoji: "🏊‍♂️", needsAttention: false)
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PathwayWidgetEntry) -> Void) {
        let entry = fetchPathwaysAndMakeEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PathwayWidgetEntry>) -> Void) {
        let entry = fetchPathwaysAndMakeEntry()
        // Update more frequently and use .atEnd to allow for dynamic updates
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchPathwaysAndMakeEntry() -> PathwayWidgetEntry {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        
        let pathways = (try? context.fetch(request)) ?? []
        let pathwayInfos = pathways.map { pathway -> PathwayInfo in
            let needsAttention: Bool
            if let activeCycle = pathway.activeCadenceCycle {
                // Get the objectives array and count completed ones
                let objectives = activeCycle.objectives?.allObjects as? [StoredObjective] ?? []
                let completedCount = objectives.filter { $0.isCompleted }.count
                needsAttention = completedCount < Int(activeCycle.count)
            } else {
                needsAttention = false
            }
            
            return PathwayInfo(
                emoji: pathway.emoji ?? "✨",
                needsAttention: needsAttention
            )
        }
        
        return PathwayWidgetEntry(date: Date(), pathways: pathwayInfos)
    }
}

// MARK: - Widget Views
struct PathwayCircleView: View {
    let info: PathwayInfo
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(info.needsAttention ? Color.red : Color.green, lineWidth: 2)
                .frame(width: 48, height: 48)
            
            Text(info.emoji)
                .font(.system(size: 24))
        }
    }
}

struct PathwayGridView: View {
    let pathways: [PathwayInfo]
    let columns: Int
    let maxItems: Int
    
    var body: some View {
        let items = pathways.prefix(maxItems)
        let rows = (items.count + columns - 1) / columns
        
        VStack(spacing: 10) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < items.count {
                            PathwayCircleView(info: items[index])
                        } else {
                            Color.clear.frame(width: 48, height: 48)
                        }
                    }
                }
            }
        }
    }
}

struct PathwayWidgetEntryView: View {
    let entry: PathwayWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var columns: Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 4
        case .systemLarge: return 4
        default: return 2
        }
    }
    
    var maxItems: Int {
        switch family {
        case .systemSmall: return 4
        case .systemMedium: return 8
        case .systemLarge: return 12
        default: return 4
        }
    }
    
    private var hasIncompletePathways: Bool {
        entry.pathways.contains { $0.needsAttention }
    }
    
    var body: some View {
        let sortedPathways = entry.pathways.sorted { $0.needsAttention && !$1.needsAttention }
        
        ZStack {
            // Glowing border
            ContainerRelativeShape()
                .fill(
                    hasIncompletePathways ?
                        LinearGradient(
                            colors: [
                                Color.red.opacity(0.6),
                                Color.red.opacity(0.3),
                                Color.red.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.6),
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .blur(radius: 3)
            
            // Content Container
            ContainerRelativeShape()
                .fill(Color(uiColor: .systemBackground))
                .padding(3)
                .overlay(
                    ZStack {
                        // Background color based on status
                        ContainerRelativeShape()
                            .fill(hasIncompletePathways ? 
                                Color.red.opacity(0.1) :
                                Color.green.opacity(0.1))
                        
                        VStack {
                            PathwayGridView(pathways: sortedPathways, columns: columns, maxItems: maxItems)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(3)
                )
        }
    }
}

// MARK: - Widget Configuration
@main
struct XPPathwayWidget: Widget {
    private let kind = "XPPathwayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: PathwayProvider()
        ) { entry in
            PathwayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pathway Status")
        .description("Shows your pathways that need attention")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
