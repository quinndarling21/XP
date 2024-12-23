import Foundation
import CoreData

enum CadenceFrequency: Int32, CaseIterable {
    case none = 0
    case daily = 1
    case weekly = 2
    case monthly = 3
    
    var description: String {
        switch self {
        case .none: return "None"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
    
    func nextEndDate(from startDate: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: startDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)
        }
    }
}

extension CadenceCycle {
    var cadenceFrequency: CadenceFrequency {
        get {
            return CadenceFrequency(rawValue: frequency) ?? .none
        }
        set {
            frequency = newValue.rawValue
        }
    }
    
    static func create(
        in context: NSManagedObjectContext,
        frequency: CadenceFrequency,
        count: Int,
        pathway: Pathway
    ) -> CadenceCycle {
        let cycle = CadenceCycle(context: context)
        cycle.id = UUID()
        cycle.startDate = Date.now
        cycle.endDate = CadenceTimeframe.nextStartDate(after: cycle.startDate!, frequency: frequency)
        cycle.frequency = frequency.rawValue
        cycle.count = Int32(count)
        cycle.isActive = true
        cycle.pathway = pathway
        cycle.activeInPathway = pathway
        cycle.currentStreak = 0
        
        return cycle
    }
    
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date.now >= endDate
    }
    
    var completedObjectivesCount: Int {
        (objectives?.allObjects as? [StoredObjective])?.filter { $0.isCompleted }.count ?? 0
    }
    
    var progress: Double {
        guard count > 0 else { return 0 }
        return Double(completedObjectivesCount) / Double(count)
    }
    
    var timeUntilReset: TimeInterval? {
        guard let endDate = endDate else { return nil }
        return endDate.timeIntervalSince(Date.now)
    }
    
    func updateForNewCycle(availableObjectives: [StoredObjective]) {
        // Clear old objective associations
        objectives?.forEach { objective in
            (objective as? StoredObjective)?.cadenceCycle = nil
        }
        
        // Select next n incomplete objectives
        let nextObjectives = availableObjectives
            .filter { !$0.isCompleted && $0.cadenceCycle == nil }
            .prefix(Int(count))
        
        // Associate new objectives with this cycle
        nextObjectives.forEach { objective in
            objective.cadenceCycle = self
        }
        
        // Update dates
        startDate = Date.now
        endDate = CadenceTimeframe.nextStartDate(after: startDate!, frequency: cadenceFrequency)
        
        // Update streak based on previous cycle completion
        if completedObjectivesCount >= Int(count) {
            currentStreak += 1
            lastCompletedDate = Date.now
        } else {
            currentStreak = 0
            lastCompletedDate = nil
        }
        
        // Verify we have enough objectives
        if nextObjectives.count < count {
            print("⚠️ Warning: Not enough available objectives for new cycle. Expected: \(count), Got: \(nextObjectives.count)")
        }
    }
} 