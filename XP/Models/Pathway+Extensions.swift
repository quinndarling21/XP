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
        colorIndex: Int,
        cadenceFrequency: CadenceFrequency = .none,
        objectivesCount: Int = 0
    ) -> Pathway {
        let pathway = Pathway(context: context)
        pathway.id = UUID()
        pathway.name = name
        pathway.descriptionText = description
        pathway.colorIndex = Int32(colorIndex)
        pathway.currentXP = 0
        pathway.currentLevel = 1
        pathway.requiredXPForLevel = 1500
        pathway.objectivesCompleted = 0
        
        // Set up cadence if specified
        if cadenceFrequency != .none {
            let cycle = CadenceCycle.create(
                in: context,
                frequency: cadenceFrequency,
                count: objectivesCount,
                pathway: pathway
            )
            pathway.activeCadenceCycle = cycle
        }
        
        return pathway
    }
    
    func createNewCadenceCycle(frequency: CadenceFrequency, count: Int) {
        guard let context = managedObjectContext else { return }
        
        // Deactivate current cycle if it exists
        activeCadenceCycle?.isActive = false
        activeCadenceCycle?.endDate = Date()
        
        // Create new cycle
        _ = CadenceCycle.create(
            in: context,
            frequency: frequency,
            count: count,
            pathway: self
        )
    }
    
    func updateCadence(frequency: CadenceFrequency, count: Int, applyImmediately: Bool = true) {
        guard let context = managedObjectContext else { return }
        
        if applyImmediately {
            // End current cycle if it exists
            if let currentCycle = activeCadenceCycle {
                currentCycle.isActive = false
                currentCycle.endDate = Date()
            }
            
            // Create new cycle if frequency isn't none
            if frequency != .none {
                _ = CadenceCycle.create(
                    in: context,
                    frequency: frequency,
                    count: count,
                    pathway: self
                )
            }
        } else {
            // Update current cycle to end at its scheduled time
            // New settings will apply on next cycle
            if let currentCycle = activeCadenceCycle {
                currentCycle.count = Int32(count)
                // Don't change frequency mid-cycle to avoid timing issues
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error updating cadence: \(error)")
        }
    }
    
    func disableCadence() {
        guard let context = managedObjectContext else { return }
        
        // End current cycle if it exists
        if let currentCycle = activeCadenceCycle {
            currentCycle.isActive = false
            currentCycle.endDate = Date()
            activeCadenceCycle = nil
        }
        
        do {
            try context.save()
        } catch {
            print("Error disabling cadence: \(error)")
        }
    }
} 
