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
        XCTAssertTrue(app.buttons["Complete"].exists)
        
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
        // Find and tap the first Complete button
        let completeButton = app.buttons["Complete"].firstMatch
        XCTAssertTrue(completeButton.exists)
        
        let initialXP = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch.label
        
        completeButton.tap()
        
        // Verify XP changed
        let newXP = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch.label
        XCTAssertNotEqual(initialXP, newXP)
    }
}
