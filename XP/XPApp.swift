//
//  XPApp.swift
//  XP
//
//  Created by Quinn Darling on 12/21/24.
//

import SwiftUI
import CoreData

@main
struct XPApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            PathwayListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
