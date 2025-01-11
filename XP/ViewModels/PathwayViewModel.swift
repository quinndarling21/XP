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
    
    func addPathway(
        name: String,
        description: String,
        colorIndex: Int,
        cadenceFrequency: CadenceFrequency = .none,
        objectivesCount: Int = 0
    ) {
        print("🛣️ Creating new pathway: \(name)")
        let pathway = Pathway.create(
            in: viewContext,
            name: name,
            description: description,
            colorIndex: colorIndex,
            cadenceFrequency: cadenceFrequency,
            objectivesCount: objectivesCount
        )
        
        print("📊 Initial objectives setup - minimum: 10, requested: \(objectivesCount)")
        let minimumObjectives = 10
        let requiredCount = max(minimumObjectives, objectivesCount)
        print("🎯 Will generate \(requiredCount) objectives")
        
        // First generate cadence objectives if applicable
        if let cycle = pathway.activeCadenceCycle {
            print("🔄 Generating \(objectivesCount) objectives for cadence cycle")
            generateObjectives(
                for: pathway,
                count: objectivesCount,
                assignToCycle: cycle
            )
        }
        
        // Then generate additional non-cadence objectives to meet minimum
        let remainingCount = requiredCount - objectivesCount
        if remainingCount > 0 {
            print("📝 Generating \(remainingCount) additional objectives")
            generateObjectives(for: pathway, count: remainingCount)
        }
        
        do {
            try viewContext.save()
            pathways.append(pathway)
            objectWillChange.send()
            print("✅ Pathway created and saved")
        } catch {
            print("❌ Error saving pathway: \(error)")
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
    
    func generateObjectives(
        for pathway: Pathway,
        count: Int = 5,
        assignToCycle cycle: CadenceCycle? = nil
    ) {
        print("\n🎯 generateObjectives called")
        print("📝 Request to generate \(count) objectives for pathway: \(pathway.name ?? "unknown")\(cycle != nil ? " (cadence cycle)" : "")")
        let request = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        request.predicate = NSPredicate(format: "pathway == %@", pathway)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoredObjective.order, ascending: true)]
        
        do {
            let existingObjectives = try viewContext.fetch(request)
            print("📊 Found \(existingObjectives.count) existing objectives")
            let highestOrder = existingObjectives.map { $0.order }.max() ?? -1
            print("📈 Highest existing order: \(highestOrder)")
            
            // Generate new objectives with sequential order
            for i in 0..<count {
                let objective = StoredObjective(context: viewContext)
                objective.id = UUID()
                objective.order = highestOrder + Int32(i) + 1
                objective.xpValue = Int32(Int.random(in: 10...50) * 10)
                objective.isCompleted = false
                objective.pathway = pathway
                objective.cadenceCycle = cycle
                print("➕ Created objective with order: \(objective.order)")
            }
            
            try viewContext.save()
            objectWillChange.send()
            print("✅ Successfully generated and saved \(count) new objectives\n")
        } catch {
            print("❌ Error generating objectives: \(error)")
        }
    }
    
    func refreshPathways() {
        let request = NSFetchRequest<Pathway>(entityName: "Pathway")
        
        do {
            // Fetch fresh data from Core Data
            viewContext.refreshAllObjects()
            pathways = try viewContext.fetch(request)
            objectWillChange.send()
        } catch {
            print("Error fetching pathways: \(error)")
        }
    }
    
    func updateUserFirstName(_ firstName: String) {
        guard let user = user else { return }
        user.firstName = firstName
        
        do {
            try viewContext.save()
            objectWillChange.send()
        } catch {
            print("Error saving user first name: \(error)")
        }
    }
} 