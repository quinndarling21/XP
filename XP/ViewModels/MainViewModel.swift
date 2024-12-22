import Foundation
import CoreData
import SwiftUI

class MainViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    @Published private(set) var user: User?
    @Published private(set) var objectives: [Objective] = []
    
    private let futureObjectivesCount = 5
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        fetchUserData()
        generateObjectives()
    }
    
    // MARK: - Data Management
    
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
    
    private func generateObjectives() {
        guard let user = user else { return }
        
        let completedCount = Int(user.objectivesCompleted)
        let totalNeeded = completedCount + futureObjectivesCount + 1
        
        // Fetch existing objectives
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            
            // Calculate how many new objectives we need
            let newObjectivesNeeded = totalNeeded - storedObjectives.count
            
            // Generate new objectives if needed
            if newObjectivesNeeded > 0 {
                let startOrder = storedObjectives.last?.order ?? -1
                for i in 0..<newObjectivesNeeded {
                    _ = StoredObjective.create(
                        in: viewContext,
                        order: Int(startOrder) + i + 1,
                        user: user
                    )
                }
                try viewContext.save()
                
                // Fetch again to get updated list
                let updatedObjectives = try viewContext.fetch(request)
                objectives = updatedObjectives.map { $0.objective }
            } else {
                objectives = storedObjectives.map { $0.objective }
            }
        } catch {
            print("Error fetching/generating objectives: \(error)")
        }
    }
    
    // MARK: - User Actions
    
    func markObjectiveComplete(_ objective: Objective) {
        guard let user = user else { return }
        
        // Find and update stored objective
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "id == %@ AND user == %@", objective.id as CVarArg, user)
        
        do {
            let storedObjectives = try viewContext.fetch(request)
            guard let storedObjective = storedObjectives.first else { return }
            
            storedObjective.isCompleted = true
            
            // Update user XP and level
            let newXP = user.currentXP + storedObjective.xpValue
            if newXP >= user.requiredXPForLevel {
                user.currentLevel += 1
                user.currentXP = newXP - user.requiredXPForLevel
                user.requiredXPForLevel += 500
            } else {
                user.currentXP = newXP
            }
            
            user.objectivesCompleted += 1
            
            try viewContext.save()
            generateObjectives()
            objectWillChange.send()
        } catch {
            print("Error completing objective: \(error)")
        }
    }
} 
