import XCTest
import CoreData
@testable import XP

final class ObjectiveManagementTests: XCTestCase {
    var persistenceController: PersistenceController!
    var pathwayViewModel: PathwayViewModel!
    var mainViewModel: MainViewModel!
    var context: NSManagedObjectContext!
    var testPathway: Pathway!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        pathwayViewModel = PathwayViewModel(persistenceController: persistenceController)
        mainViewModel = MainViewModel(persistenceController: persistenceController)
        
        // Create a test pathway
        pathwayViewModel.addPathway(
            name: "Test Pathway",
            description: "Test Description",
            colorIndex: 0
        )
        testPathway = pathwayViewModel.pathways.first!
    }
    
    override func tearDown() {
        testPathway = nil
        persistenceController = nil
        pathwayViewModel = nil
        mainViewModel = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - Objective Creation Tests
    
    func testObjectiveGeneration() {
        // Given
        let initialCount = 5
        
        // When
        pathwayViewModel.generateObjectives(for: testPathway, count: initialCount)
        
        // Then
        let objectives = mainViewModel.objectives(for: testPathway)
        XCTAssertEqual(objectives.count, initialCount + 10) // +10 from initial pathway creation
        
        // Verify objective properties
        objectives.forEach { objective in
            XCTAssertFalse(objective.isCompleted)
            XCTAssertTrue(objective.xpValue >= 100 && objective.xpValue <= 500)
            XCTAssertTrue(objective.xpValue % 10 == 0) // Should be multiple of 10
        }
    }
    
    func testObjectiveOrdering() {
        // Given
        pathwayViewModel.generateObjectives(for: testPathway, count: 5)
        
        // When
        let objectives = mainViewModel.objectives(for: testPathway)
        
        // Then
        // Check that objectives are ordered correctly
        for i in 1..<objectives.count {
            XCTAssertTrue(objectives[i-1].order < objectives[i].order)
        }
    }
    
    // MARK: - Objective Completion Tests
    
    func testObjectiveCompletion() {
        // Given
        let objectives = mainViewModel.objectives(for: testPathway)
        let objective = objectives.first!
        let initialPathwayXP = testPathway.currentXP
        let initialUserXP = mainViewModel.user?.currentXP ?? 0
        
        // When
        mainViewModel.markObjectiveComplete(objective, in: testPathway)
        
        // Then
        // Refresh objects from context
        context.refresh(testPathway, mergeChanges: true)
        
        // Check objective completion
        let updatedObjectives = mainViewModel.objectives(for: testPathway)
        XCTAssertTrue(updatedObjectives.first?.isCompleted ?? false)
        
        // Check XP awards
        XCTAssertGreaterThan(testPathway.currentXP, initialPathwayXP)
        XCTAssertGreaterThan(mainViewModel.user?.currentXP ?? 0, initialUserXP)
        
        // Check objective count
        XCTAssertEqual(testPathway.objectivesCompleted, 1)
    }
    
    func testLevelUpOnCompletion() {
        // Given
        let objectives = mainViewModel.objectives(for: testPathway)
        let objective = objectives.first!
        
        // Manually set XP close to level-up threshold
        testPathway.currentXP = testPathway.requiredXPForLevel - Int32(objective.xpValue) + 10
        let initialLevel = testPathway.currentLevel
        
        // When
        mainViewModel.markObjectiveComplete(objective, in: testPathway)
        
        // Then
        XCTAssertGreaterThan(testPathway.currentLevel, initialLevel)
        XCTAssertLessThan(testPathway.currentXP, testPathway.requiredXPForLevel)
    }
    
    func testNewObjectiveGenerationOnCompletion() {
        // Given
        let initialObjectives = mainViewModel.objectives(for: testPathway)
        let initialCount = initialObjectives.count
        let objective = initialObjectives.first!
        
        // When
        mainViewModel.markObjectiveComplete(objective, in: testPathway)
        
        // Then
        let updatedObjectives = mainViewModel.objectives(for: testPathway)
        // Expect count to increase by 1 since we keep completed objectives
        XCTAssertEqual(updatedObjectives.count, initialCount + 1)
        
        // Verify completed objective is still present
        XCTAssertTrue(updatedObjectives.contains { $0.id == objective.id })
        XCTAssertTrue(updatedObjectives.first { $0.id == objective.id }?.isCompleted ?? false)
        
        // Verify new objective was added
        let newObjectives = updatedObjectives.filter { updatedObj in 
            !initialObjectives.contains { initialObj in 
                initialObj.id == updatedObj.id 
            }
        }
        XCTAssertEqual(newObjectives.count, 1)
        XCTAssertFalse(newObjectives.first?.isCompleted ?? true)
    }
    
    func testCadenceObjectiveCompletion() {
        // Given
        pathwayViewModel.addPathway(
            name: "Cadence Pathway",
            description: "Test",
            colorIndex: 0,
            cadenceFrequency: .daily,
            objectivesCount: 3
        )
        guard let cadencePathway = pathwayViewModel.pathways.last,
              let cycle = cadencePathway.activeCadenceCycle else {
            XCTFail("Failed to create cadence pathway")
            return
        }
        
        let objectives = mainViewModel.objectives(for: cadencePathway)
        let cadenceObjective = objectives.first { $0.isInCurrentCycle }!
        
        // When
        mainViewModel.markObjectiveComplete(cadenceObjective, in: cadencePathway)
        
        // Then
        XCTAssertEqual(cycle.completedObjectivesCount, 1)
        XCTAssertEqual(cycle.progress, 1.0/3.0)
    }
} 
