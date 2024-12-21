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
    
    func testInitialViewLoads() throws {
        // For now, just verify the initial "Hello, world!" text is present
        // We'll update this test as we build out the UI
        XCTAssertTrue(app.staticTexts["Hello, world!"].exists)
    }
}
