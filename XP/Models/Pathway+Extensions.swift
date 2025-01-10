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
        
        if let currentCycle = activeCadenceCycle {
            if applyImmediately {
                print("\n🔄 Updating cadence settings")
                print("📊 Current state:")
                print("- Streak: \(currentCycle.currentStreak)")
                print("- Last completed: \(String(describing: currentCycle.lastCompletedDate))")
                print("- Current frequency: \(currentCycle.cadenceFrequency)")
                print("- Current count: \(currentCycle.count)")
                print("- Is complete? \(currentCycle.isCompleted)")
                
                // Store current state
                let previousStreak = currentCycle.currentStreak
                let completedObjectives = currentCycle.objectives?
                    .allObjects
                    .compactMap { $0 as? StoredObjective }
                    .filter { $0.isCompleted } ?? []
                let completedCount = completedObjectives.count
                let wasComplete = currentCycle.isCompleted
                
                print("\n📝 Completed objectives: \(completedCount)")
                print("🎯 New settings:")
                print("- Frequency: \(frequency)")
                print("- Required count: \(count)")
                
                // Update cycle settings
                currentCycle.frequency = frequency.rawValue
                currentCycle.count = Int32(count)
                
                // Check completion status under new count
                if completedCount >= count && !wasComplete {
                    print("\n✨ Cycle newly completed under new settings")
                    print("- Incrementing streak from \(previousStreak) to \(previousStreak + 1)")
                    currentCycle.lastCompletedDate = Date.now
                    currentCycle.currentStreak = previousStreak + 1
                } else if completedCount < count && wasComplete {
                    print("\n⚠️ Cycle no longer complete under new settings")
                    print("- Completed: \(completedCount)/\(count)")
                    print("- Reverting streak from \(previousStreak) to \(max(0, previousStreak - 1))")
                    currentCycle.lastCompletedDate = nil
                    currentCycle.currentStreak = max(0, previousStreak - 1)
                } else {
                    print("\n📌 No change in completion status")
                    print("- Was complete? \(wasComplete)")
                    print("- Completed count: \(completedCount)/\(count)")
                    print("- Maintaining streak at \(previousStreak)")
                }
                
                // Reset end date based on new frequency
                currentCycle.endDate = frequency.nextEndDate(from: Date.now)
                print("\n⏰ Updated end date to: \(String(describing: currentCycle.endDate))")
                
                // Keep existing completed objectives, only add new ones if needed
                if completedCount < count {
                    let availableObjectives = fetchAvailableObjectives()
                    let neededCount = count - completedCount
                    
                    print("\n🎯 Updating objectives:")
                    print("- Need \(neededCount) more objectives")
                    print("- Available objectives: \(availableObjectives.count)")
                    
                    // Clear non-completed objectives
                    currentCycle.objectives?.allObjects
                        .compactMap { $0 as? StoredObjective }
                        .filter { !$0.isCompleted }
                        .forEach { $0.cadenceCycle = nil }
                    
                    // Add new objectives as needed
                    availableObjectives.prefix(neededCount).forEach { objective in
                        objective.cadenceCycle = currentCycle
                    }
                } else {
                    // If we have enough completed objectives, just remove any uncompleted ones
                    print("\n🎯 Cleaning up objectives:")
                    print("- Required count: \(count)")
                    print("- Completed count: \(completedCount)")
                    
                    // Remove all uncompleted objectives from the cycle
                    currentCycle.objectives?.allObjects
                        .compactMap { $0 as? StoredObjective }
                        .filter { !$0.isCompleted }
                        .forEach { objective in
                            print("- Removing uncompleted objective: \(objective.id?.uuidString ?? "unknown")")
                            objective.cadenceCycle = nil
                        }
                }
                
                print("\n✅ Final state:")
                print("- Streak: \(currentCycle.currentStreak)")
                print("- Last completed: \(String(describing: currentCycle.lastCompletedDate))")
                print("- Is complete? \(currentCycle.isCompleted)")
            } else {
                // Only update count if not changing immediately
                currentCycle.count = Int32(count)
            }
        } else if frequency != .none {
            // Create new cycle if none exists
            _ = CadenceCycle.create(
                in: context,
                frequency: frequency,
                count: count,
                pathway: self
            )
        }
        
        do {
            try context.save()
            // Notify observers that pathway was updated
            NotificationCenter.default.post(name: NSNotification.Name("PathwayDidUpdate"), object: nil)
        } catch {
            print("❌ Error updating cadence: \(error)")
        }
    }
    
    private func fetchAvailableObjectives() -> [StoredObjective] {
        guard let context = managedObjectContext else { return [] }
        
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "pathway == %@ AND isCompleted == NO", self)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching available objectives: \(error)")
            return []
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
