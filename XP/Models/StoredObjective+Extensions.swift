import Foundation
import CoreData

extension StoredObjective {
    var objective: Objective {
        Objective(
            id: id ?? UUID(),
            xpValue: Int(xpValue),
            isCompleted: isCompleted,
            order: Int(order),
            isInCurrentCycle: cadenceCycle?.isActive == true
        )
    }
    
    static func create(
        in context: NSManagedObjectContext,
        order: Int,
        pathway: Pathway,
        cycle: CadenceCycle? = nil
    ) -> StoredObjective {
        let storedObjective = StoredObjective(context: context)
        storedObjective.id = UUID()
        storedObjective.order = Int32(order)
        storedObjective.xpValue = Int32(Int.random(in: 10...50) * 10)
        storedObjective.isCompleted = false
        storedObjective.pathway = pathway
        storedObjective.cadenceCycle = cycle
        return storedObjective
    }
    
    var isPartOfActiveCycle: Bool {
        cadenceCycle?.isActive == true
    }
} 