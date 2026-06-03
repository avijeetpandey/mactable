//
//  MacTableUITests.swift
//  mactableUITests
//

import XCTest

final class MacTableUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsApp() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["MacTable"].waitForExistence(timeout: 5))
    }
}
