import Foundation
import CoreData
import SwiftUI

extension Pathway {
    var pathwayColor: Color {
        // Assign a unique color based on the pathway's ID or name
        return Color.blue // Example color
    }
    
    static func create(in context: NSManagedObjectContext, name: String, description: String) -> Pathway {
        let pathway = Pathway(context: context)
        pathway.id = UUID()
        pathway.name = name
        pathway.descriptionText = description
        pathway.currentLevel = 1
        pathway.currentXP = 0
        pathway.requiredXPForLevel = 1000
        pathway.objectivesCompleted = 0
        return pathway
    }
} 
