//
//  XPWidgetExtension.swift
//  XPWidgetExtension
//
//  Created by Quinn Darling on 1/11/25.
//

import WidgetKit
import SwiftUI
import CoreData

// MARK: - 1) Timeline Entry
struct DataCheckWidgetEntry: TimelineEntry {
    let date: Date
    let pathwayCount: Int
    let userFirstName: String?
}

// MARK: - 2) Timeline Provider
struct DataCheckProvider: TimelineProvider {
    
    let persistenceController: PersistenceController
    
    init() {
        persistenceController = PersistenceController.shared
    }
    
    // Placeholder: Shown in widget gallery
    func placeholder(in context: Context) -> DataCheckWidgetEntry {
        DataCheckWidgetEntry(
            date: Date(),
            pathwayCount: 0,
            userFirstName: "Loading..."
        )
    }

    // Snapshot: Used in certain quick refresh scenarios
    func getSnapshot(in context: Context, completion: @escaping (DataCheckWidgetEntry) -> Void) {
        let entry = fetchDataAndMakeEntry()
        completion(entry)
    }

    // Main timeline refresh
    func getTimeline(in context: Context, completion: @escaping (Timeline<DataCheckWidgetEntry>) -> Void) {
        let entry = fetchDataAndMakeEntry()
        // Let’s update every 30 minutes, for testing
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - Data Fetch
    private func fetchDataAndMakeEntry() -> DataCheckWidgetEntry {
        print("Widget: Starting data fetch")
        let context = persistenceController.container.viewContext
        
        // Fetch pathway count
        let pathwayFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Pathway")
        let pathwayCount = (try? context.count(for: pathwayFetch)) ?? 0
        print("Widget: Found \(pathwayCount) pathways")
        
        // Fetch user's first name
        let userFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        userFetch.fetchLimit = 1
        let users = (try? context.fetch(userFetch) as? [NSManagedObject]) ?? []
        let firstName = users.first?.value(forKey: "firstName") as? String
        print("Widget: Found user firstName: \(String(describing: firstName))")
        
        return DataCheckWidgetEntry(
            date: Date(),
            pathwayCount: pathwayCount,
            userFirstName: firstName
        )
    }
}

// MARK: - 3) Widget View
struct DataCheckWidgetEntryView: View {
    let entry: DataCheckWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let name = entry.userFirstName {
                Text("Hello, \(name)!")
                    .font(.headline)
            }
            
            Text("Active Pathways: \(entry.pathwayCount)")
                .font(.subheadline)
        }
        .padding()
    }
}

// MARK: - 4) Main widget config
@main
struct XPDataCheckWidget: Widget {
    private let kind = "XPDataCheckWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DataCheckProvider()
        ) { entry in
            DataCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("XP Status")
        .description("Shows your XP progress")
        .supportedFamilies([.systemSmall])
    }
}
