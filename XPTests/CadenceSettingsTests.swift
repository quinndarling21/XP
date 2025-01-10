import XCTest
import CoreData
@testable import XP

final class CadenceSettingsTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var pathway: Pathway!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        
        // Create a test pathway with daily cadence
        pathway = Pathway.create(
            in: context,
            name: "Test Pathway",
            description: "Test Description",
            colorIndex: 0,
            cadenceFrequency: .daily,
            objectivesCount: 2
        )
        try? context.save()
    }
    
    // MARK: - Cadence Update Tests
    
    func testReducingCountMaintainsExistingStreak() {
        // Given a cycle with existing streak and completion
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // Set up initial state directly
        cycle.currentStreak = 5
        cycle.lastCompletedDate = Date()
        let initialLastCompletedDate = cycle.lastCompletedDate
        
        // When reducing count
        pathway.updateCadence(frequency: .daily, count: 1)
        
        // Then streak and completion status should be unchanged
        XCTAssertEqual(cycle.currentStreak, 5, "Streak should remain unchanged")
        XCTAssertEqual(cycle.lastCompletedDate, initialLastCompletedDate, "Completion date should remain unchanged")
    }
    
    func testIncreasingCountWithIncompleteObjectives() {
        // Given a cycle with existing streak
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // Set up initial state
        cycle.currentStreak = 3
        cycle.lastCompletedDate = nil // Current cycle not complete
        
        // When increasing count
        pathway.updateCadence(frequency: .daily, count: 3)
        
        // Then streak should remain unchanged since cycle wasn't complete
        XCTAssertEqual(cycle.currentStreak, 3, "Streak should remain unchanged")
        XCTAssertNil(cycle.lastCompletedDate, "Completion date should remain nil")
    }
    
    // MARK: - Objective Management Tests
    
    func testObjectiveRetentionOnCountDecrease() {
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // Set up completed objectives directly
        let objectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
        objectives.forEach { $0.isCompleted = true }
        let initialCompletedCount = objectives.count
        
        // When reducing required count
        pathway.updateCadence(frequency: .daily, count: 1)
        
        // Then all completed objectives should remain
        let remainingObjectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
        XCTAssertEqual(remainingObjectives.count, initialCompletedCount, "Should keep all completed objectives")
        XCTAssertTrue(remainingObjectives.allSatisfy({ $0.isCompleted }), "All remaining objectives should be completed")
    }
    
//    func testObjectiveCleanupOnCountIncrease() {
//        guard let cycle = pathway.activeCadenceCycle else {
//            XCTFail("No active cycle")
//            return
//        }
//        
//        // Set up some completed and incomplete objectives
//        let objectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
//        objectives.first?.isCompleted = true
//        let completedCount = objectives.filter { $0.isCompleted }.count
//        
//        // When increasing required count
//        let newRequiredCount = 3
//        pathway.updateCadence(frequency: .daily, count: newRequiredCount)
//        
//        // Then should:
//        // 1. Keep completed objectives
//        // 2. Add (newCount - completedCount) new objectives
//        let updatedObjectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
//        let expectedTotal = completedCount + (newRequiredCount - completedCount)
//        XCTAssertEqual(updatedObjectives.count, expectedTotal, "Should have correct total count")
//        XCTAssertEqual(updatedObjectives.filter({ $0.isCompleted }).count, completedCount, "Should keep completed objectives")
//    }
//    
    // MARK: - Delayed Application Tests
    
    func testDelayedCadenceUpdate() {
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        let initialFrequency = cycle.frequency
        let initialEndDate = cycle.endDate
        
        // When updating with delayed application
        pathway.updateCadence(frequency: .weekly, count: 3, applyImmediately: false)
        
        // Then only count should change
        XCTAssertEqual(cycle.frequency, initialFrequency, "Frequency should not change")
        XCTAssertEqual(cycle.endDate, initialEndDate, "End date should not change")
        XCTAssertEqual(cycle.count, 3, "Count should update")
    }
} 
