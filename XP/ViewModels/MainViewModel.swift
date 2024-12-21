import Foundation
import CoreData
import SwiftUI

class MainViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    @Published private(set) var user: User?
    @Published private(set) var objectives: [Objective] = []
    
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
                // Create a new user if none exists
                let newUser = persistenceController.createUser()
                try viewContext.save()
                self.user = newUser
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    private func generateObjectives() {
        // For V0, generate 3 random objectives
        objectives = (0..<3).map { _ in Objective() }
    }
    
    // MARK: - User Actions
    
    func markObjectiveComplete(_ objective: Objective) {
        guard var updatedObjective = objectives.first(where: { $0.id == objective.id }),
              let user = user else {
            return
        }
        
        // Update objective state
        updatedObjective.isCompleted = true
        
        // Update user XP (placeholder implementation)
        user.currentXP += Int32(updatedObjective.xpValue)
        
        do {
            try viewContext.save()
            objectWillChange.send()
        } catch {
            print("Error saving completion: \(error)")
        }
    }
} 