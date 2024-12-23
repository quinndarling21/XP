import XCTest
import CoreData
@testable import XP

final class CadenceCycleTests: XCTestCase {
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        context = PersistenceController(inMemory: true).container.viewContext
    }
    
    // MARK: - Cycle Creation Tests
    
    func testCycleCreation() {
        // Given
        let pathway = Pathway(context: context)
        pathway.id = UUID()
        
        // When
        let cycle = CadenceCycle.create(
            in: context,
            frequency: .daily,
            count: 3,
            pathway: pathway
        )
        
        // Then
        XCTAssertNotNil(cycle.id)
        XCTAssertNotNil(cycle.startDate)
        XCTAssertNotNil(cycle.endDate)
        XCTAssertEqual(cycle.count, 3)
        XCTAssertEqual(cycle.frequency, CadenceFrequency.daily.rawValue)
        XCTAssertEqual(cycle.currentStreak, 0)
        XCTAssertTrue(cycle.isActive)
        XCTAssertEqual(cycle.pathway, pathway)
        XCTAssertEqual(cycle.activeInPathway, pathway)
    }
    
    // MARK: - Streak Tests
    
    func testStreakIncreasesWhenCycleCompleted() {
        // Given
        let cycle = createCycleWithObjectives(count: 2)
        cycle.currentStreak = 0
        
        // When
        // Complete all objectives
        cycle.objectives?.allObjects.forEach { objective in
            (objective as? StoredObjective)?.isCompleted = true
        }
        
        // Then
        XCTAssertEqual(cycle.completedObjectivesCount, 2)
        XCTAssertEqual(cycle.progress, 1.0)
    }
    
    func testStreakResetWhenCycleExpiredWithIncompleteObjectives() {
        // Given
        let cycle = createCycleWithObjectives(count: 2)
        cycle.currentStreak = 5 // Existing streak
        
        // When
        // Complete only one objective
        if let objective = cycle.objectives?.allObjects.first as? StoredObjective {
            objective.isCompleted = true
        }
        
        // Then
        XCTAssertEqual(cycle.completedObjectivesCount, 1)
        XCTAssertEqual(cycle.progress, 0.5)
    }
    
    // MARK: - Helper Methods
    
    private func createCycleWithObjectives(count: Int) -> CadenceCycle {
        let pathway = Pathway(context: context)
        pathway.id = UUID()
        
        let cycle = CadenceCycle.create(
            in: context,
            frequency: .daily,
            count: count,
            pathway: pathway
        )
        
        // Create objectives
        for _ in 0..<count {
            let objective = StoredObjective(context: context)
            objective.id = UUID()
            objective.isCompleted = false
            objective.pathway = pathway
            objective.cadenceCycle = cycle
        }
        
        return cycle
    }
    
    func testUpdateForNewCycleWithAvailableObjectives() {
        // Given
        let cycle = createCycleWithObjectives(count: 2)
        let oldObjectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
        
        // Create some new available objectives
        let newObjectives = (0..<3).map { _ -> StoredObjective in
            let obj = StoredObjective(context: context)
            obj.id = UUID()
            obj.isCompleted = false
            obj.pathway = cycle.pathway
            return obj
        }
        
        // When
        cycle.updateForNewCycle(availableObjectives: newObjectives)
        
        // Then
        // Old objectives should be detached
        oldObjectives.forEach { objective in
            XCTAssertNil(objective.cadenceCycle)
        }
        
        // New objectives should be attached
        let currentObjectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
        XCTAssertEqual(currentObjectives.count, 2)
        currentObjectives.forEach { objective in
            XCTAssertFalse(objective.isCompleted)
            XCTAssertEqual(objective.cadenceCycle, cycle)
        }
    }
    
    func testUpdateForNewCycleWithInsufficientObjectives() {
        // Given
        let cycle = createCycleWithObjectives(count: 3)
        let newObjectives = (0..<1).map { _ -> StoredObjective in
            let obj = StoredObjective(context: context)
            obj.id = UUID()
            obj.isCompleted = false
            obj.pathway = cycle.pathway
            return obj
        }
        
        // When
        cycle.updateForNewCycle(availableObjectives: newObjectives)
        
        // Then
        let currentObjectives = cycle.objectives?.allObjects as? [StoredObjective] ?? []
        XCTAssertEqual(currentObjectives.count, 1)
    }
} 
