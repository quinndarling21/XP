import Foundation
import CoreData
import SwiftUI

extension Pathway {
    static let pathwayColors: [Color] = [
        .blue,
        .purple,
        .green,
        .orange,
        .pink,
        .teal,
        .indigo,
        .red
    ]
    
    var pathwayColor: Color {
        Self.pathwayColors[Int(colorIndex)]
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
