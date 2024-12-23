//import XCTest
//import CoreData
//@testable import XP
//
//final class MainViewModelTests: XCTestCase {
//    var persistenceController: PersistenceController!
//    var viewModel: MainViewModel!
//    
//    override func setUpWithError() throws {
//        persistenceController = PersistenceController(inMemory: true)
//        viewModel = MainViewModel(persistenceController: persistenceController)
//    }
//    
//    override func tearDownWithError() throws {
//        try persistenceController.container.viewContext.save()
//        persistenceController = nil
//        viewModel = nil
//    }
//    
//    // MARK: - Initial State Tests
//    
//    func testInitialState() throws {
//        XCTAssertNotNil(viewModel.user)
//        XCTAssertFalse(viewModel.objectives.isEmpty)
//        XCTAssertEqual(viewModel.objectives.count, 6) // Current + 5 future
//    }
//    
//    // MARK: - Objective Generation Tests
//    
//    func testObjectiveGeneration() throws {
//        // Verify initial objectives
//        XCTAssertEqual(viewModel.objectives.count, 6)
//        
//        // Complete first objective
//        guard let firstObjective = viewModel.objectives.first else {
//            XCTFail("No objectives available")
//            return
//        }
//        
//        viewModel.markObjectiveComplete(firstObjective)
//        
//        // After completing an objective:
//        // 1. The completed objective should still be visible
//        // 2. We should maintain 5 future objectives
//        // So total should still be 6 (1 completed + current + 4 future)
//        XCTAssertEqual(viewModel.objectives.count, 7) // 1 completed + current + 5 future
//        
//        // Verify we have a completed objective
//        XCTAssertTrue(viewModel.objectives.contains { $0.isCompleted })
//        
//        // Verify ordering is maintained
//        for i in 1..<viewModel.objectives.count {
//            XCTAssertGreaterThan(viewModel.objectives[i].order, viewModel.objectives[i-1].order)
//        }
//    }
//    
//    func testObjectiveOrdering() throws {
//        let objectives = viewModel.objectives
//        
//        // Verify objectives are in order
//        for i in 1..<objectives.count {
//            XCTAssertLessThan(objectives[i-1].order, objectives[i].order)
//        }
//    }
//    
//    // MARK: - XP and Level Tests
//    
//    func testLevelUpMechanic() throws {
//        let initialLevel = viewModel.user?.currentLevel ?? 1
//        let requiredXP = viewModel.user?.requiredXPForLevel ?? 1000
//        
//        // Set XP close to level up
//        viewModel.user?.currentXP = Int32(requiredXP - 50)
//        
//        // Complete an objective that will trigger level up
//        guard let levelUpObjective = viewModel.objectives.first(where: { $0.xpValue >= 50 }) else {
//            XCTFail("No suitable objective found")
//            return
//        }
//        
//        viewModel.markObjectiveComplete(levelUpObjective)
//        
//        // Verify level up
//        XCTAssertEqual(viewModel.user?.currentLevel, initialLevel + 1)
//        XCTAssertLessThan(viewModel.user?.currentXP ?? 0, viewModel.user?.requiredXPForLevel ?? 1000)
//    }
//    
//    func testXPAccumulation() throws {
//        let initialXP = viewModel.user?.currentXP ?? 0
//        
//        guard let objective = viewModel.objectives.first else {
//            XCTFail("No objectives available")
//            return
//        }
//        
//        viewModel.markObjectiveComplete(objective)
//        
//        XCTAssertEqual(
//            viewModel.user?.currentXP,
//            initialXP + Int32(objective.xpValue)
//        )
//    }
//    
//    // MARK: - Persistence Tests
//    
//    func testObjectivePersistence() throws {
//        guard let objective = viewModel.objectives.first else {
//            XCTFail("No objectives available")
//            return
//        }
//        
//        viewModel.markObjectiveComplete(objective)
//        
//        // Create new view model instance
//        let newViewModel = MainViewModel(persistenceController: persistenceController)
//        
//        // Verify completed objective persisted
//        XCTAssertTrue(newViewModel.objectives.contains { $0.isCompleted })
//    }
//} 
