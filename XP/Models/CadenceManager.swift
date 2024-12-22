import Foundation
import CoreData

class CadenceManager {
    static let shared = CadenceManager()
    
    private let calendar = Calendar.current
    
    func checkAndUpdateCycles(in context: NSManagedObjectContext) {
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        request.predicate = NSPredicate(format: "activeCadenceCycle != nil")
        
        do {
            let pathways = try context.fetch(request)
            var hasChanges = false
            
            for pathway in pathways {
                if handleCycleReset(for: pathway) {
                    hasChanges = true
                }
            }
            
            if hasChanges {
                try context.save()
                NotificationCenter.default.post(
                    name: NSNotification.Name("CyclesDidReset"),
                    object: nil
                )
            }
        } catch {
            print("Error checking cycles: \(error)")
        }
    }
    
    private func handleCycleReset(for pathway: Pathway) -> Bool {
        guard let activeCycle = pathway.activeCadenceCycle,
              activeCycle.isExpired else { return false }
        
        // End current cycle
        endCycle(activeCycle)
        
        // Create new cycle if needed
        if activeCycle.cadenceFrequency != .none {
            createNewCycle(
                for: pathway,
                frequency: activeCycle.cadenceFrequency,
                count: Int(activeCycle.count)
            )
        }
        
        return true
    }
    
    private func endCycle(_ cycle: CadenceCycle) {
        cycle.isActive = false
        cycle.endDate = Date()
        
        // Archive cycle data if needed
        archiveCycleData(cycle)
    }
    
    private func archiveCycleData(_ cycle: CadenceCycle) {
        // Here you could add logic to store cycle statistics
        // or perform any cleanup needed
    }
    
    private func createNewCycle(for pathway: Pathway, frequency: CadenceFrequency, count: Int) {
        guard let context = pathway.managedObjectContext else { return }
        
        let startDate = Date()
        let cycle = CadenceCycle.create(
            in: context,
            frequency: frequency,
            count: count,
            pathway: pathway
        )
        
        // Select objectives for the new cycle
        selectObjectivesForCycle(cycle, count: count)
    }
    
    private func selectObjectivesForCycle(_ cycle: CadenceCycle, count: Int) {
        guard let context = cycle.managedObjectContext,
              let pathway = cycle.pathway else { return }
        
        // First, try to find existing incomplete objectives
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(
            format: "pathway == %@ AND isCompleted == NO AND cadenceCycle == nil",
            pathway
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        request.fetchLimit = count
        
        do {
            let existingObjectives = try context.fetch(request)
            let remainingCount = count - existingObjectives.count
            
            // Assign existing objectives to the cycle
            existingObjectives.forEach { objective in
                objective.cadenceCycle = cycle
            }
            
            // Generate new objectives if needed
            for i in 0..<remainingCount {
                let objective = StoredObjective.create(
                    in: context,
                    order: existingObjectives.count + i,
                    pathway: pathway,
                    cycle: cycle
                )
            }
        } catch {
            print("Error selecting objectives for cycle: \(error)")
        }
    }
    
    func calculateNextEndDate(from startDate: Date, frequency: CadenceFrequency) -> Date? {
        let calendar = Calendar.current
        
        switch frequency {
        case .none:
            return nil
            
        case .daily:
            // Next day at midnight
            guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startDate) else { return nil }
            return calendar.startOfDay(for: tomorrow)
            
        case .weekly:
            // Next Monday at midnight
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate)
            components.weekOfYear! += 1
            components.weekday = 2 // Monday
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components)
            
        case .monthly:
            // First day of next month at midnight
            var components = calendar.dateComponents([.year, .month], from: startDate)
            components.month! += 1
            components.day = 1
            components.hour = 0
            components.minute = 0
            components.second = 0
            return calendar.date(from: components)
        }
    }
} 