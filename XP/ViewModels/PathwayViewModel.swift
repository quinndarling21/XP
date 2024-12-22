import Foundation
import CoreData
import SwiftUI

class PathwayViewModel: ObservableObject {
    private let persistenceController: PersistenceController
    private var viewContext: NSManagedObjectContext
    
    @Published private(set) var pathways: [Pathway] = []
    @Published private(set) var user: User?
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.viewContext = persistenceController.container.viewContext
        
        fetchPathways()
        fetchUserData()
    }
    
    func fetchPathways() {
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        
        do {
            pathways = try viewContext.fetch(request)
        } catch {
            print("Error fetching pathways: \(error)")
        }
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
    
    func addPathway(name: String, description: String) {
        let newPathway = Pathway.create(in: viewContext, name: name, description: description)
        pathways.append(newPathway)
        
        generateObjectives(for: newPathway)
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving new pathway: \(error)")
        }
    }
    
    func removePathway(_ pathway: Pathway) {
        viewContext.delete(pathway)
        
        do {
            try viewContext.save()
            fetchPathways()
        } catch {
            print("Error removing pathway: \(error)")
        }
    }
    
    private func generateObjectives(for pathway: Pathway) {
        for i in 0..<5 {
            let objective = StoredObjective(context: viewContext)
            objective.id = UUID()
            objective.order = Int32(i)
            objective.xpValue = Int32(Int.random(in: 10...50) * 10)
            objective.isCompleted = false
            objective.pathway = pathway
        }
    }
} 