//
//  XPTests.swift
//  XPTests
//
//  Created by Quinn Darling on 12/21/24.
//

import XCTest
import CoreData
@testable import XP

final class XPTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDownWithError() throws {
        try context.save()
        persistenceController = nil
        context = nil
    }
    
    // MARK: - Objective Tests
    
    func testObjectiveInitialization() throws {
        // Test with default random XP
        let objective1 = Objective()
        XCTAssertNotNil(objective1.id)
        XCTAssertFalse(objective1.isCompleted)
        XCTAssertTrue(objective1.xpValue >= 100 && objective1.xpValue <= 500)
        XCTAssertEqual(objective1.xpValue % 10, 0) // Divisible by 10
        
        // Test with specific XP value
        let objective2 = Objective(xpValue: 250)
        XCTAssertEqual(objective2.xpValue, 250)
    }
    
    // MARK: - User Tests
    
    func testUserDefaultValues() throws {
        let user = persistenceController.createUser()
        
        // Test default values
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.currentLevel, 1)
        XCTAssertEqual(user.currentXP, 0)
        XCTAssertEqual(user.requiredXPForLevel, 1000)
        XCTAssertEqual(user.objectivesCompleted, 0)
        XCTAssertNil(user.streakStartDate)
        XCTAssertNil(user.streakEndDate)
    }
    
    func testAutomaticUUIDGeneration() throws {
        // Create user directly without helper method
        let user = User(context: context)
        
        // UUID should be automatically set
        XCTAssertNotNil(user.id)
        
        // Create multiple users and verify unique IDs
        let user2 = User(context: context)
        let user3 = User(context: context)
        
        XCTAssertNotEqual(user.id, user2.id)
        XCTAssertNotEqual(user2.id, user3.id)
        XCTAssertNotEqual(user.id, user3.id)
    }
    
    func testUserPersistence() throws {
        // Create and save a user
        let user = persistenceController.createUser()
        user.currentXP = 500
        user.currentLevel = 2
        
        try context.save()
        
        // Fetch the user
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        let users = try context.fetch(fetchRequest)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.currentXP, 500)
        XCTAssertEqual(users.first?.currentLevel, 2)
    }
}
