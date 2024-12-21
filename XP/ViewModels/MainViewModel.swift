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
                let newUser = persistenceController.createUser()
                try viewContext.save()
                self.user = newUser
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    private func generateObjectives() {
        // Generate 3 random objectives with XP values between 100-500 (multiples of 10)
        objectives = (0..<3).map { _ in
            Objective()
        }
    }
    
    // MARK: - User Actions
    
    func markObjectiveComplete(_ objective: Objective) {
        guard let user = user,
              !objective.isCompleted else { return }
        
        // Update objective state
        if let index = objectives.firstIndex(where: { $0.id == objective.id }) {
            objectives[index].isCompleted = true
        }
        
        // Add XP
        let newXP = user.currentXP + Int32(objective.xpValue)
        
        // Check for level up
        if newXP >= user.requiredXPForLevel {
            user.currentLevel += 1
            user.currentXP = newXP - user.requiredXPForLevel
            // Could also increase requiredXPForLevel for next level if desired
            user.requiredXPForLevel += 500 // Simple increment for now
        } else {
            user.currentXP = newXP
        }
        
        // Increment objectives completed
        user.objectivesCompleted += 1
        
        // Save changes
        do {
            try viewContext.save()
            objectWillChange.send()
        } catch {
            print("Error saving completion: \(error)")
        }
    }
} 