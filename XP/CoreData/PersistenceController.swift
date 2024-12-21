import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    static var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "XP", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "XP", managedObjectModel: Self.managedObjectModel)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let viewContext = container.viewContext
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            
            viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // Helper method to create a new user with defaults
    func createUser() -> User {
        let user = User(context: container.viewContext)
        user.id = UUID()
        return user
    }
} 