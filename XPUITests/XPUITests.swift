//
//  XPUITests.swift
//  XPUITests
//
//  Created by Quinn Darling on 12/21/24.
//

import XCTest

final class XPUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testInitialLayout() throws {
        // Verify objectives exist
        XCTAssertTrue(app.buttons["objective-node"].firstMatch.exists)
        
        // Verify XP bar exists
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Level'")).firstMatch.exists)
        XCTAssertTrue(app.progressIndicators.firstMatch.exists)
    }
    
    func testObjectiveCompletion() throws {
        // Find and tap START objective
        let startButton = app.staticTexts["START"].firstMatch
        XCTAssertTrue(startButton.exists, "START button should exist")
        startButton.tap()
        
        // Complete the objective
        let completeButton = app.buttons["Mark as Complete"]
        XCTAssertTrue(completeButton.exists, "Complete button should exist")
        completeButton.tap()
        
        // Verify new START appears
        XCTAssertTrue(app.staticTexts["START"].exists, "New START button should appear")
    }
    
    func testCompletedObjectiveAccess() throws {
        // Complete an objective
        let startButton = app.staticTexts["START"].firstMatch
        XCTAssertTrue(startButton.exists, "START button should exist")
        startButton.tap()
        app.buttons["Mark as Complete"].tap()
        
        // Verify completed objective is still tappable
        let completedObjective = app.images["checkmark"].firstMatch
        XCTAssertTrue(completedObjective.exists, "Completed objective should be tappable")
        
        // Find and tap the completed objective node
        let completedNode = app.buttons["objective-node"].firstMatch
        completedNode.tap()
        
        // Verify detail view shows but without complete button
        XCTAssertTrue(app.staticTexts["Reward"].exists, "Detail view should show reward")
        XCTAssertFalse(app.buttons["Mark as Complete"].exists, "Complete button should not exist")
    }
}
