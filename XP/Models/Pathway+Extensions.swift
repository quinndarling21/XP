import Foundation
import CoreData
import SwiftUI

extension Pathway {
    static let pathwayColors: [Color] = [
        .flame,
        .delftBlue,
        .orangeWeb,
        .olivine,
        .airSuperiorityBlue
    ]
    
    var pathwayColor: Color {
        let index = Int(colorIndex)
        return Self.pathwayColors.indices.contains(index) ? Self.pathwayColors[index] : Self.pathwayColors[0]
    }
    
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        description: String,
        colorIndex: Int
    ) -> Pathway {
        let pathway = Pathway(context: context)
        pathway.id = UUID()
        pathway.name = name
        pathway.descriptionText = description
        pathway.currentLevel = 1
        pathway.currentXP = 0
        pathway.requiredXPForLevel = 1000
        pathway.objectivesCompleted = 0
        pathway.colorIndex = Int32(colorIndex)
        return pathway
    }
} 
