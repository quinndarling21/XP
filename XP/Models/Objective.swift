import Foundation

struct Objective: Identifiable {
    let id: UUID
    let xpValue: Int
    var isCompleted: Bool
    let order: Int
    let isInCurrentCycle: Bool
    
    init(id: UUID, xpValue: Int, isCompleted: Bool, order: Int, isInCurrentCycle: Bool = false) {
        self.id = id
        self.xpValue = xpValue
        self.isCompleted = isCompleted
        self.order = order
        self.isInCurrentCycle = isInCurrentCycle
    }
} 
