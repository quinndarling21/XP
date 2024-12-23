import Foundation
import CoreData

class CadenceManager {
    static let shared = CadenceManager()
    private let context = PersistenceController.shared.container.viewContext
    
    func checkAndUpdateCycles() {
        let fetchRequest: NSFetchRequest<CadenceCycle> = CadenceCycle.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        
        do {
            let activeCycles = try context.fetch(fetchRequest)
            print("📅 Checking \(activeCycles.count) active cycles...")
            
            for cycle in activeCycles {
                print("""
                    \n🔄 Cycle ID: \(cycle.id?.uuidString ?? "unknown")
                    📊 Progress: \(cycle.completedObjectivesCount)/\(cycle.count)
                    📆 Start: \(cycle.startDate?.description ?? "nil")
                    ⏰ End: \(cycle.endDate?.description ?? "nil")
                    ⚡️ Expired: \(cycle.isExpired)
                    🎯 Frequency: \(cycle.cadenceFrequency.description)
                    """)
                
                if cycle.isExpired {
                    print("♻️ Updating expired cycle...")
                    updateExpiredCycle(cycle)
                    print("✅ Cycle updated - New end date: \(cycle.endDate?.description ?? "nil")")
                }
            }
            
            try context.save()
            print("💾 Changes saved to Core Data")
        } catch {
            print("❌ Error checking cycles: \(error)")
        }
    }
    
    private func updateExpiredCycle(_ cycle: CadenceCycle) {
        print("\n♻️ Updating expired cycle")
        guard let pathway = cycle.pathway else {
            print("⚠️ Cannot update cycle - no pathway found")
            return
        }
        
        // Fetch all available objectives for this pathway
        let objectivesFetch: NSFetchRequest<StoredObjective> = StoredObjective.fetchRequest()
        objectivesFetch.predicate = NSPredicate(
            format: "pathway == %@ AND isCompleted == NO AND cadenceCycle == nil",
            pathway
        )
        objectivesFetch.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let availableObjectives = try context.fetch(objectivesFetch)
            print("📝 Found \(availableObjectives.count) available objectives")
            cycle.updateForNewCycle(availableObjectives: availableObjectives)
            
            // Generate new objectives if needed
            if availableObjectives.count < Int(cycle.count) {
                print("⚠️ Not enough available objectives, generating more")
                let pathwayViewModel = PathwayViewModel(persistenceController: .shared)
                pathwayViewModel.generateObjectives(
                    for: pathway,
                    count: Int(cycle.count) - availableObjectives.count
                )
            }
        } catch {
            print("❌ Error fetching available objectives: \(error)")
        }
    }
} 