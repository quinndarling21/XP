import XCTest
import CoreData
@testable import XP

final class CadenceManagementTests: XCTestCase {
    var persistenceController: PersistenceController!
    var pathwayViewModel: PathwayViewModel!
    var mainViewModel: MainViewModel!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        pathwayViewModel = PathwayViewModel(persistenceController: persistenceController)
        mainViewModel = MainViewModel(persistenceController: persistenceController)
    }
    
    // MARK: - Cadence Creation Tests
    
    func testCadenceCreation() {
        // Given
        let pathway = createPathwayWithCadence(frequency: .daily, count: 3)
        
        // Then
        XCTAssertNotNil(pathway.activeCadenceCycle)
        XCTAssertEqual(pathway.activeCadenceCycle?.cadenceFrequency, .daily)
        XCTAssertEqual(pathway.activeCadenceCycle?.count, 3)
        XCTAssertEqual(pathway.activeCadenceCycle?.currentStreak, 0)
        XCTAssertNotNil(pathway.activeCadenceCycle?.startDate)
        XCTAssertNotNil(pathway.activeCadenceCycle?.endDate)
    }
    
    // MARK: - Progress Tracking Tests
    
    func testCadenceProgress() {
        // Given
        let pathway = createPathwayWithCadence(frequency: .daily, count: 3)
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        let objectives = mainViewModel.objectives(for: pathway)
        let cadenceObjective = objectives.first { $0.isInCurrentCycle }!
        
        // When
        mainViewModel.markObjectiveComplete(cadenceObjective, in: pathway)
        
        // Then
        XCTAssertEqual(cycle.completedObjectivesCount, 1)
        XCTAssertEqual(cycle.progress, 1.0/3.0)
    }
    
    // MARK: - Streak Tests
    
    func testStreakIncrement() {
        // Given
        let pathway = createPathwayWithCadence(frequency: .daily, count: 1)
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // When - Complete all objectives in cycle
        let objectives = mainViewModel.objectives(for: pathway)
        let cadenceObjective = objectives.first { $0.isInCurrentCycle }!
        mainViewModel.markObjectiveComplete(cadenceObjective, in: pathway)
        
        // Then
        XCTAssertEqual(cycle.currentStreak, 1)
        XCTAssertNotNil(cycle.lastCompletedDate)
    }
    
    func testStreakReset() {
        // Given
        let pathway = createPathwayWithCadence(frequency: .daily, count: 1)
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // Set up initial streak
        let objectives = mainViewModel.objectives(for: pathway)
        let cadenceObjective = objectives.first { $0.isInCurrentCycle }!
        mainViewModel.markObjectiveComplete(cadenceObjective, in: pathway)
        XCTAssertEqual(cycle.currentStreak, 1)
        
        // When - Simulate time passing by setting last completed date to 2 days ago
        cycle.lastCompletedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        cycle.validateStreak()
        
        // Then
        XCTAssertEqual(cycle.currentStreak, 0)
    }
    
    // MARK: - Cycle Reset Tests
    
    func testCycleReset() {
        // Given
        let pathway = createPathwayWithCadence(frequency: .daily, count: 2)
        guard let cycle = pathway.activeCadenceCycle else {
            XCTFail("No active cycle")
            return
        }
        
        // When - Set end date to past to trigger reset
        cycle.endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        CadenceManager.shared.checkAndUpdateCycles()
        
        // Then
        XCTAssertNotEqual(cycle.endDate, pathway.activeCadenceCycle?.endDate)
        XCTAssertGreaterThan(pathway.activeCadenceCycle?.endDate ?? Date(), Date())
    }
    
    // MARK: - Helper Methods
    
    private func createPathwayWithCadence(
        frequency: CadenceFrequency,
        count: Int
    ) -> Pathway {
        pathwayViewModel.addPathway(
            name: "Test Pathway",
            description: "Test Description",
            colorIndex: 0,
            cadenceFrequency: frequency,
            objectivesCount: count
        )
        return pathwayViewModel.pathways.first!
    }
} 