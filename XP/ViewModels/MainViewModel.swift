import Foundation
import CoreData
import SwiftUI

class MainViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    @Published private(set) var user: User?
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        fetchUserData()
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
            
            storedObjective.isCompleted = true
            
            // Update pathway XP and level
            let newPathwayXP = pathway.currentXP + storedObjective.xpValue
            if newPathwayXP >= pathway.requiredXPForLevel {
                pathway.currentLevel += 1
                pathway.currentXP = newPathwayXP - pathway.requiredXPForLevel
                pathway.requiredXPForLevel += 500
            } else {
                pathway.currentXP = newPathwayXP
            }
            
            // Update completed objectives count
            pathway.objectivesCompleted += 1
            
            // Update user XP and level
            let newUserXP = user.currentXP + storedObjective.xpValue
            if newUserXP >= user.requiredXPForLevel {
                user.currentLevel += 1
                user.currentXP = newUserXP - user.requiredXPForLevel
                user.requiredXPForLevel += 500
            } else {
                user.currentXP = newUserXP
            }
            
            // Save changes and notify observers
            try viewContext.save()
            objectWillChange.send()
            NotificationCenter.default.post(name: NSNotification.Name("UserXPDidChange"), object: nil)
            
            // Generate new objectives if needed
            generateObjectives(for: pathway)
        } catch {
            print("Error completing objective: \(error)")
        }
    }
    
    func objectives(for pathway: Pathway) -> [Objective] {
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "pathway == %@", pathway)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            return storedObjectives.map { $0.objective }
        } catch {
            print("Error fetching objectives: \(error)")
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
} 
