import XCTest
import CoreData
@testable import XP

final class MainViewModelTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewModel: MainViewModel!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        viewModel = MainViewModel(persistenceController: persistenceController)
    }
    
    override func tearDownWithError() throws {
        try persistenceController.container.viewContext.save()
        persistenceController = nil
        viewModel = nil
    }
    
    func testInitialUserCreation() throws {
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.currentLevel, 1)
        XCTAssertEqual(viewModel.user?.currentXP, 0)
    }
    
    func testObjectivesGeneration() throws {
        XCTAssertEqual(viewModel.objectives.count, 3)
        
        // Verify XP values are within expected range
        for objective in viewModel.objectives {
            XCTAssertTrue(objective.xpValue >= 100 && objective.xpValue <= 500)
            XCTAssertEqual(objective.xpValue % 10, 0)
            XCTAssertFalse(objective.isCompleted)
        }
    }
    
    func testMarkObjectiveComplete() throws {
        guard let objective = viewModel.objectives.first else {
            XCTFail("No objectives available")
            return
        }
        
        let initialXP = viewModel.user?.currentXP ?? 0
        viewModel.markObjectiveComplete(objective)
        
        // Verify XP was added
        XCTAssertEqual(viewModel.user?.currentXP, initialXP + Int32(objective.xpValue))
    }
    
    func testLevelUpMechanic() throws {
        // Set up user close to level up
        viewModel.user?.currentXP = viewModel.user?.requiredXPForLevel ?? 1000 - 50
        let initialLevel = viewModel.user?.currentLevel ?? 1
        
        // Find an objective with enough XP to trigger level up
        guard let levelUpObjective = viewModel.objectives.first(where: { $0.xpValue >= 50 }) else {
            XCTFail("No suitable objective found")
            return
        }
        
        // Complete the objective
        viewModel.markObjectiveComplete(levelUpObjective)
        
        // Verify level up occurred
        XCTAssertEqual(viewModel.user?.currentLevel, initialLevel + 1)
        XCTAssertLessThan(viewModel.user?.currentXP ?? 0, viewModel.user?.requiredXPForLevel ?? 1000)
    }
    
    func testObjectiveCompletionIncrement() throws {
        let initialCompleted = viewModel.user?.objectivesCompleted ?? 0
        
        // Complete an objective
        guard let objective = viewModel.objectives.first else {
            XCTFail("No objectives available")
            return
        }
        
        viewModel.markObjectiveComplete(objective)
        
        // Verify increment
        XCTAssertEqual(viewModel.user?.objectivesCompleted, initialCompleted + 1)
    }
    
    func testObjectiveXPRange() throws {
        // Test that all objectives have valid XP values
        for objective in viewModel.objectives {
            XCTAssertTrue(objective.xpValue >= 100 && objective.xpValue <= 500)
            XCTAssertEqual(objective.xpValue % 10, 0, "XP value should be multiple of 10")
        }
    }
} 