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
    
    var isCompleted: Bool {
        completedObjectivesCount >= Int(count)
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
        print("\n🔄 Starting updateForNewCycle")
        print("📊 Current state:")
        print("- Current streak: \(currentStreak)")
        print("- Completed objectives: \(completedObjectivesCount)")
        print("- Required count: \(count)")
        print("- Last completed date: \(String(describing: lastCompletedDate))")
        
        // Preserve streak info before resetting
        let wasLastCycleCompleted = isCompleted
        let previousStreak = currentStreak
        
        print("🎯 Previous cycle status:")
        print("- Was completed? \(wasLastCycleCompleted)")
        print("- Previous streak: \(previousStreak)")
        print("- Current end date: \(String(describing: endDate))")
        
        // Check if streak should continue based on cycle timing
        var shouldKeepStreak = wasLastCycleCompleted
        
        print("🔄 Streak continuation:")
        print("- Should keep streak? \(shouldKeepStreak)")
        
        // Clear old objective associations and set up new ones
        objectives?.forEach { objective in
            (objective as? StoredObjective)?.cadenceCycle = nil
        }
        
        let nextObjectives = availableObjectives
            .filter { !$0.isCompleted }
            .prefix(Int(count))
        
        nextObjectives.forEach { objective in
            objective.cadenceCycle = self
        }
        
        // Update dates
        startDate = Date.now
        endDate = CadenceTimeframe.nextStartDate(after: startDate!, frequency: cadenceFrequency)
        
        // Handle streak for new cycle
        if shouldKeepStreak {
            // Keep the existing streak
            print("✨ Maintaining streak of \(previousStreak)")
            currentStreak = previousStreak
        } else {
            // Reset streak
            print("💔 Breaking streak due to incomplete cycle or time gap")
            currentStreak = 0
        }
        
        // Reset completion status for new cycle
        lastCompletedDate = nil
        
        print("🏁 Finished updateForNewCycle")
        print("- Final streak: \(currentStreak)")
        print("- Next completion target: \(String(describing: endDate))")
    }
    
    func validateStreak() {
        print("🔍 Validating streak:")
        print("- Current streak: \(currentStreak)")
        print("- Last completed date: \(String(describing: lastCompletedDate))")
        
        guard let lastCompleted = lastCompletedDate else {
            if currentStreak > 0 {
                print("⚠️ Inconsistency: Have streak but no last completed date")
            }
            return
        }
        
        let calendar = Calendar.current
        let now = Date.now
        
        switch cadenceFrequency {
        case .daily:
            let daysSinceCompletion = calendar.dateComponents([.day], from: lastCompleted, to: now).day ?? 0
            print("📅 Days since last completion: \(daysSinceCompletion)")
            if daysSinceCompletion > 1 && currentStreak > 0 {
                print("⚠️ Streak should be reset - more than 1 day since last completion")
            }
        case .weekly:
            let weeksSinceCompletion = calendar.dateComponents([.weekOfYear], from: lastCompleted, to: now).weekOfYear ?? 0
            print("📅 Weeks since last completion: \(weeksSinceCompletion)")
            if weeksSinceCompletion > 1 && currentStreak > 0 {
                print("⚠️ Streak should be reset - more than 1 week since last completion")
            }
        case .monthly:
            let monthsSinceCompletion = calendar.dateComponents([.month], from: lastCompleted, to: now).month ?? 0
            print("📅 Months since last completion: \(monthsSinceCompletion)")
            if monthsSinceCompletion > 1 && currentStreak > 0 {
                print("⚠️ Streak should be reset - more than 1 month since last completion")
            }
        case .none:
            print("ℹ️ No frequency set - streaks not applicable")
        }
    }
    
    func checkAndUpdateStreak() {
        print("\n🔄 Checking streak status:")
        print("- Current streak: \(currentStreak)")
        print("- Completed count: \(completedObjectivesCount)")
        print("- Required count: \(count)")
        print("- Is expired? \(isExpired)")
        
        // Only update streak if cycle isn't expired yet
        if !isExpired {
            if isCompleted {
                // Only update if this is our first time completing all objectives in this cycle
                if lastCompletedDate == nil {
                    // If this is our first completion ever, start at 1
                    // Otherwise, increment the existing streak
                    currentStreak = (currentStreak == 0) ? 1 : currentStreak + 1
                    lastCompletedDate = Date.now
                    print("✨ All objectives completed! Streak updated to: \(currentStreak)")
                    
                    // Save the context after updating the streak
                    if let context = self.managedObjectContext {
                        do {
                            try context.save()
                            print("💾 Streak saved to Core Data")
                        } catch {
                            print("❌ Error saving streak: \(error)")
                        }
                    }
                } else {
                    print("ℹ️ Objectives already marked as completed for this cycle")
                }
            }
        } else {
            print("⏰ Cycle is expired, no streak updates allowed")
        }
        
        validateStreak()
    }
} 