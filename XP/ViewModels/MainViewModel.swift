import Foundation
import CoreData
import SwiftUI

class MainViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    private let pathwayViewModel: PathwayViewModel
    private let cadenceManager = CadenceManager.shared
    
    @Published private(set) var user: User?
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        self.pathwayViewModel = PathwayViewModel(persistenceController: persistenceController)
        
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
        print("\n🎯 markObjectiveComplete called")
        print("📝 Marking objective \(objective.id) complete in pathway: \(pathway.name ?? "unknown")")
        guard let user = user else { return }
        
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "id == %@", objective.id as CVarArg)
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            guard let storedObjective = storedObjectives.first else { return }
            
            storedObjective.isCompleted = true
            
            // Generate one new objective
            print("🆕 Requesting generation of 1 new objective")
            let pathwayViewModel = PathwayViewModel(persistenceController: persistenceController)
            pathwayViewModel.generateObjectives(for: pathway, count: 1)
            
            // 2. Update pathway XP and level
            let newPathwayXP = pathway.currentXP + storedObjective.xpValue
            if newPathwayXP >= pathway.requiredXPForLevel {
                pathway.currentLevel += 1
                pathway.currentXP = newPathwayXP - pathway.requiredXPForLevel
                pathway.requiredXPForLevel += 500
            } else {
                pathway.currentXP = newPathwayXP
            }
            
            // 4. Update user XP and level
            let newUserXP = user.currentXP + storedObjective.xpValue
            if newUserXP >= user.requiredXPForLevel {
                user.currentLevel += 1
                user.currentXP = newUserXP - user.requiredXPForLevel
                user.requiredXPForLevel += 500
            } else {
                user.currentXP = newUserXP
            }
            
            // 5. Update completed objectives count for pathway
            pathway.objectivesCompleted += 1
            
            try viewContext.save()
            print("💾 Changes saved")
            
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
            print("❌ Error completing objective: \(error)")
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
        print("📊 Fetching objectives for pathway: \(pathway.name ?? "unknown")")
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "pathway == %@", pathway)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            print("📝 Found \(storedObjectives.count) objectives")
            return storedObjectives.map { $0.objective }
        } catch {
            print("❌ Error fetching objectives: \(error)")
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
        cadenceManager.checkAndUpdateCycles()
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
