import Foundation
import CoreData
import SwiftUI

class CadenceViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        checkCadenceResets()
    }
    
    func createNewCadenceCycle(for pathway: Pathway, frequency: CadenceFrequency, count: Int) {
        guard let context = pathway.managedObjectContext else { return }
        
        // End current cycle if exists
        if let currentCycle = pathway.activeCadenceCycle {
            endCadenceCycle(currentCycle)
        }
        
        // Create new cycle
        let cycle = CadenceCycle.create(
            in: context,
            frequency: frequency,
            count: count,
            pathway: pathway
        )
        
        // Select objectives for the cycle
        selectObjectivesForCycle(cycle, count: count)
        
        do {
            try context.save()
            objectWillChange.send()
            NotificationCenter.default.post(name: NSNotification.Name("CycleDidUpdate"), object: nil)
        } catch {
            print("Error creating cycle: \(error)")
        }
    }
    
    private func selectObjectivesForCycle(_ cycle: CadenceCycle, count: Int) {
        guard let context = cycle.managedObjectContext,
              let pathway = cycle.pathway else { return }
        
        // Find existing incomplete objectives
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
            
            // Assign existing objectives
            existingObjectives.forEach { objective in
                objective.cadenceCycle = cycle
            }
            
            // Create new objectives if needed
            for i in 0..<remainingCount {
                let objective = StoredObjective.create(
                    in: context,
                    order: existingObjectives.count + i,
                    pathway: pathway,
                    cycle: cycle
                )
            }
        } catch {
            print("Error selecting objectives: \(error)")
        }
    }
    
    func endCadenceCycle(_ cycle: CadenceCycle) {
        guard let context = cycle.managedObjectContext else { return }
        
        cycle.isActive = false
        if cycle.endDate == nil {
            cycle.endDate = Date()
        }
        
        do {
            try context.save()
            objectWillChange.send()
            NotificationCenter.default.post(name: NSNotification.Name("CycleDidEnd"), object: nil)
        } catch {
            print("Error ending cycle: \(error)")
        }
    }
    
    func checkCadenceResets() {
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        request.predicate = NSPredicate(format: "activeCadenceCycle != nil")
        
        do {
            let pathways = try viewContext.fetch(request)
            var hasChanges = false
            
            for pathway in pathways {
                if let activeCycle = pathway.activeCadenceCycle, activeCycle.isExpired {
                    endCadenceCycle(activeCycle)
                    
                    // Create new cycle if frequency isn't none
                    if activeCycle.cadenceFrequency != .none {
                        createNewCadenceCycle(
                            for: pathway,
                            frequency: activeCycle.cadenceFrequency,
                            count: Int(activeCycle.count)
                        )
                    }
                    
                    hasChanges = true
                }
            }
            
            if hasChanges {
                try viewContext.save()
                objectWillChange.send()
                NotificationCenter.default.post(name: NSNotification.Name("CyclesDidReset"), object: nil)
            }
        } catch {
            print("Error checking resets: \(error)")
        }
    }
    
    func objectivesInActiveCadence(for pathway: Pathway) -> [StoredObjective] {
        guard let activeCycle = pathway.activeCadenceCycle else { return [] }
        
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "cadenceCycle == %@", activeCycle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching cycle objectives: \(error)")
            return []
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 