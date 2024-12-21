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
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testObjectivesDisplay() throws {
        // Verify we have objectives displayed
        let objectiveCard = app.buttons["objective-card"].firstMatch
        XCTAssertTrue(objectiveCard.exists)
        
        // Verify XP values are shown
        let xpTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'XP'"))
        XCTAssertGreaterThan(xpTexts.count, 0)
    }
    
    func testXPBarDisplay() throws {
        // Verify level is shown
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Level'")).firstMatch.exists)
        
        // Verify progress bar exists
        XCTAssertTrue(app.progressIndicators.firstMatch.exists)
    }
    
    func testObjectiveCompletion() throws {
        // Find and tap the first objective card
        let objectiveCard = app.buttons["objective-card"].firstMatch
        XCTAssertTrue(objectiveCard.exists)
        objectiveCard.tap()
        
        // Give the sheet time to animate
        Thread.sleep(forTimeInterval: 1)
        
        // Get initial XP value
        let initialXP = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch.label
        
        // Complete the objective
        let completeButton = app.buttons["Mark as Complete"]
        XCTAssertTrue(completeButton.exists)
        completeButton.tap()
        
        // Verify XP changed
        let newXP = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch.label
        XCTAssertNotEqual(initialXP, newXP)
    }
    
    func testObjectiveDetailView() throws {
        // Find and tap the first objective card
        let objectiveCard = app.buttons["objective-card"].firstMatch
        XCTAssertTrue(objectiveCard.exists)
        objectiveCard.tap()
        
        // Give the sheet time to animate
        Thread.sleep(forTimeInterval: 1)
        
        // Verify the mark as complete button exists
        let completeButton = app.buttons["Mark as Complete"]
        XCTAssertTrue(completeButton.exists)
        
        // Complete the objective
        completeButton.tap()
        
        // Verify the sheet dismisses
        XCTAssertFalse(completeButton.exists)
    }
}
