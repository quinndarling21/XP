import Foundation

struct Objective: Identifiable {
    let id: UUID
    let xpValue: Int
    var isCompleted: Bool
    
    init(xpValue: Int? = nil, isCompleted: Bool = false) {
        self.id = UUID()
        // Generate random XP value between 100-500, divisible by 10
        self.xpValue = xpValue ?? (Int.random(in: 10...50) * 10)
        self.isCompleted = isCompleted
    }
} 