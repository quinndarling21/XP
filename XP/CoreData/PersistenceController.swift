import CoreData
import WidgetKit

final class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    static var managedObjectModel: NSManagedObjectModel = {
        // Keep your existing model loading
        let modelURL = Bundle.main.url(forResource: "XP", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    init(inMemory: Bool = false) {
        // 1) Create the container with your existing model
        let container = NSPersistentContainer(name: "XP", managedObjectModel: Self.managedObjectModel)
        
        // 2) If running in-memory (tests), store in /dev/null
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Attempt to place the .sqlite file in the App Group container
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.XP") {
                let storeURL = appGroupURL.appendingPathComponent("XPModel.sqlite")
                
                if let storeDescription = container.persistentStoreDescriptions.first {
                    storeDescription.url = storeURL
                    // Enable lightweight migration options
                    storeDescription.setOption(true as NSNumber,
                                               forKey: NSMigratePersistentStoresAutomaticallyOption)
                    storeDescription.setOption(true as NSNumber,
                                               forKey: NSInferMappingModelAutomaticallyOption)
                }
            }
        }
        
        // 3) Load the persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            
            // 4) Merge policy and auto-merge
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            container.viewContext.automaticallyMergesChangesFromParent = true
            
            // Add notification for changes
            NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: container.viewContext, queue: .main) { _ in
                #if !WIDGET_EXTENSION
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            }
        }
        
        // 5) Assign the container to our class property
        self.container = container
    }
    
    // Helper method to create a new user with defaults
    func createUser() -> User {
        let user = User(context: container.viewContext)
        user.id = UUID()
        return user
    }
}
