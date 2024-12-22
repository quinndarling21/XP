import Foundation
import CoreData
import SwiftUI

class MainViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    @Published private(set) var user: User?
    
    private let cadenceManager = CadenceManager.shared
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        fetchUserData()
        
        // Set up observation of app state
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    func fetchUserData() {
        let request = NSFetchRequest<User>(entityName: "User")
        
        do {
            let users = try viewContext.fetch(request)
            if let existingUser = users.first {
                self.user = existingUser
            } else {
                let newUser = persistenceController.createUser()
                try viewContext.save()
                self.user = newUser
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    func markObjectiveComplete(_ objective: Objective, in pathway: Pathway) {
        guard let user = user else { return }
        
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "id == %@", objective.id as CVarArg)
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            guard let storedObjective = storedObjectives.first else { return }
            
            // 1. Mark objective as completed
            storedObjective.isCompleted = true
            
            // 2. Update pathway XP and level
            let newPathwayXP = pathway.currentXP + storedObjective.xpValue
            if newPathwayXP >= pathway.requiredXPForLevel {
                pathway.currentLevel += 1
                pathway.currentXP = newPathwayXP - pathway.requiredXPForLevel
                pathway.requiredXPForLevel += 500
            } else {
                pathway.currentXP = newPathwayXP
            }
            
            // 3. Update user XP and level
            let newUserXP = user.currentXP + storedObjective.xpValue
            if newUserXP >= user.requiredXPForLevel {
                user.currentLevel += 1
                user.currentXP = newUserXP - user.requiredXPForLevel
                user.requiredXPForLevel += 500
            } else {
                user.currentXP = newUserXP
            }
            
            // 4. Update completed objectives count for pathway
            pathway.objectivesCompleted += 1
            
            // 5. Save changes to Core Data
            try viewContext.save()
            
            // 6. Refresh Core Data objects
            viewContext.refresh(pathway, mergeChanges: true)
            viewContext.refresh(user, mergeChanges: true)
            if let cycle = storedObjective.cadenceCycle {
                viewContext.refresh(cycle, mergeChanges: true)
            }
            
            // 7. Notify of changes
            objectWillChange.send()
            NotificationCenter.default.post(name: NSNotification.Name("UserXPDidChange"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("PathwayDidUpdate"), object: nil)
            
            // 8. Check if all cycle objectives are complete
            if let cycle = storedObjective.cadenceCycle, cycle.isActive {
                checkCycleCompletion(cycle)
            }
            
        } catch {
            print("Error completing objective: \(error)")
        }
    }
    
    private func checkCycleCompletion(_ cycle: CadenceCycle) {
        // This method can be used to trigger any special behavior when all objectives in a cycle are completed
        if cycle.completedObjectivesCount == cycle.count {
            NotificationCenter.default.post(
                name: NSNotification.Name("CycleCompleted"),
                object: nil,
                userInfo: ["cycleID": cycle.id as Any]
            )
        }
    }
    
    func objectives(for pathway: Pathway) -> [Objective] {
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        
        if let activeCycle = pathway.activeCadenceCycle {
            // Get both cycle objectives AND non-cycle objectives
            request.predicate = NSPredicate(
                format: "pathway == %@ AND (cadenceCycle == %@ OR cadenceCycle == nil)",
                pathway, activeCycle
            )
        } else {
            // Just get all pathway objectives
            request.predicate = NSPredicate(format: "pathway == %@", pathway)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            return storedObjectives.map { $0.objective }
        } catch {
            print("Error fetching objectives: \(error)")
            return []
        }
    }
    
    private func getCurrentCycleObjectives(for cycle: CadenceCycle) -> [StoredObjective] {
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "cadenceCycle == %@", cycle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching cycle objectives: \(error)")
            return []
        }
    }
    
    private func generateObjectives(for pathway: Pathway) {
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "pathway == %@", pathway)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            
            // Get the highest order number
            let highestOrder = storedObjectives.map { $0.order }.max() ?? -1
            
            // Create one new objective with the next order number
            let objective = StoredObjective(context: viewContext)
            objective.id = UUID()
            objective.order = highestOrder + 1
            objective.xpValue = Int32(Int.random(in: 10...50) * 10)
            objective.isCompleted = false
            objective.pathway = pathway
            
            try viewContext.save()
            objectWillChange.send()
        } catch {
            print("Error generating objectives: \(error)")
        }
    }
    
    func deletePathway(_ pathway: Pathway) {
        viewContext.delete(pathway)
        
        do {
            try viewContext.save()
            NotificationCenter.default.post(name: NSNotification.Name("PathwayDidUpdate"), object: nil)
        } catch {
            print("Error deleting pathway: \(error)")
        }
    }
    
    func checkCadenceResets() {
        cadenceManager.checkAndUpdateCycles(in: viewContext)
        // Refresh UI after potential updates
        objectWillChange.send()
    }
    
    @objc private func appDidBecomeActive() {
        checkCadenceResets()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
