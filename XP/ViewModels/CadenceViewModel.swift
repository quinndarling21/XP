import Foundation
import CoreData
import SwiftUI

class CadenceViewModel: ObservableObject {
    @Published var cycle: CadenceCycle?
    private let manager = CadenceManager.shared
    
    func checkForUpdates() {
        manager.checkAndUpdateCycles()
    }
    
    // func updateCycle(
    //     pathway: Pathway,
    //     frequency: CadenceFrequency,
    //     count: Int,
    //     applyImmediately: Bool
    // ) {
    //     if applyImmediately {
    //         // Create or update cycle immediately
    //         let context = PersistenceController.shared.container.viewContext
            
    //         if let existingCycle = pathway.activeCadenceCycle {
    //             existingCycle.frequency = frequency.rawValue
    //             existingCycle.count = Int32(count)
    //         } else {
    //             let newCycle = CadenceCycle.create(
    //                 in: context,
    //                 frequency: frequency,
    //                 count: count,
    //                 pathway: pathway
    //             )
    //             pathway.activeCadenceCycle = newCycle
    //         }
            
    //         try? context.save()
    //     } else {
    //         // Store settings to apply at next reset
    //         pathway.pendingCadenceFrequency = frequency.rawValue
    //         pathway.pendingCadenceCount = Int32(count)
    //         try? PersistenceController.shared.container.viewContext.save()
    //     }
    // }
} 