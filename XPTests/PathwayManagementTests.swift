import XCTest
import CoreData
@testable import XP

final class PathwayManagementTests: XCTestCase {
    var persistenceController: PersistenceController!
    var viewModel: PathwayViewModel!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // Create an in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
        viewModel = PathwayViewModel(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        persistenceController = nil
        viewModel = nil
        context = nil
        super.tearDown()
    }
    
    // MARK: - Creation Tests
    
    func testPathwayCreation() {
        // Given
        let name = "Test Pathway"
        let description = "Test Description"
        let colorIndex = 0
        
        // When
        viewModel.addPathway(
            name: name,
            description: description,
            colorIndex: colorIndex
        )
        
        // Then
        XCTAssertEqual(viewModel.pathways.count, 1)
        let pathway = viewModel.pathways.first
        XCTAssertNotNil(pathway)
        XCTAssertEqual(pathway?.name, name)
        XCTAssertEqual(pathway?.descriptionText, description)
        XCTAssertEqual(pathway?.colorIndex, Int32(colorIndex))
        XCTAssertEqual(pathway?.currentLevel, 1)
        XCTAssertEqual(pathway?.currentXP, 0)
        XCTAssertEqual(pathway?.requiredXPForLevel, 1500)
        XCTAssertEqual(pathway?.objectivesCompleted, 0)
    }
    
    func testPathwayCreationWithCadence() {
        // Given
        let name = "Test Pathway"
        let description = "Test Description"
        let colorIndex = 0
        let frequency = CadenceFrequency.daily
        let objectivesCount = 3
        
        // When
        viewModel.addPathway(
            name: name,
            description: description,
            colorIndex: colorIndex,
            cadenceFrequency: frequency,
            objectivesCount: objectivesCount
        )
        
        // Then
        XCTAssertEqual(viewModel.pathways.count, 1)
        let pathway = viewModel.pathways.first
        XCTAssertNotNil(pathway?.activeCadenceCycle)
        XCTAssertEqual(pathway?.activeCadenceCycle?.cadenceFrequency, frequency)
        XCTAssertEqual(pathway?.activeCadenceCycle?.count, Int32(objectivesCount))
    }
    
    func testMinimumObjectivesGeneration() {
        // Given
        let name = "Test Pathway"
        let description = "Test Description"
        
        // When
        viewModel.addPathway(
            name: name,
            description: description,
            colorIndex: 0
        )
        
        // Then
        let pathway = viewModel.pathways.first
        let objectivesRequest = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        objectivesRequest.predicate = NSPredicate(format: "pathway == %@", pathway!)
        let objectives = try? context.fetch(objectivesRequest)
        
        // Should generate minimum 10 objectives
        XCTAssertEqual(objectives?.count, 10)
    }
    
    // MARK: - Deletion Tests
    
    func testPathwayDeletion() {
        // Given
        viewModel.addPathway(
            name: "Test Pathway",
            description: "Test Description",
            colorIndex: 0
        )
        XCTAssertEqual(viewModel.pathways.count, 1)
        
        // When
        if let pathway = viewModel.pathways.first {
            viewModel.removePathway(pathway)
        }
        
        // Then
        XCTAssertEqual(viewModel.pathways.count, 0)
    }
    
    func testPathwayDeletionCascade() {
        // Given
        viewModel.addPathway(
            name: "Test Pathway",
            description: "Test Description",
            colorIndex: 0,
            cadenceFrequency: .daily,
            objectivesCount: 3
        )
        
        guard let pathway = viewModel.pathways.first else {
            XCTFail("Failed to create pathway")
            return
        }
        
        // When
        viewModel.removePathway(pathway)
        
        // Then
        // Check that associated objectives were deleted
        let objectivesRequest = NSFetchRequest<StoredObjective>(entityName: "StoredObjective")
        let objectives = try? context.fetch(objectivesRequest)
        XCTAssertEqual(objectives?.count, 0)
        
        // Check that associated cycles were deleted
        let cyclesRequest = NSFetchRequest<CadenceCycle>(entityName: "CadenceCycle")
        let cycles = try? context.fetch(cyclesRequest)
        XCTAssertEqual(cycles?.count, 0)
    }
} 