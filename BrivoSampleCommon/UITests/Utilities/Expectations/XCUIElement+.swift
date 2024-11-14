//
//  XCUIElement+.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 18.04.2024.
//

import XCTest

extension XCUIElement {
    var hasFocus: Bool { value(forKey: "hasKeyboardFocus") as? Bool ?? false }

    func waitForExistence(withTimeout timeout: TimeInterval = BaseTest.TestsConstants.defaultWaitTime) {
        XCTAssertTrue(waitForExistence(timeout: timeout), "failed to get element: \(self)")
    }

    func checkForExistence(timeout: Double = BaseTest.TestsConstants.defaultWaitTime) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 1"), object: self )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func waitUntilExists(timeout: TimeInterval = BaseTest.TestsConstants.defaultWaitTime) -> XCUIElement {
        let elementExists = waitForExistence(timeout: timeout)
        if elementExists {
            return self
        } else {
            XCTFail("Could not find \(self) before timeout")
        }
        return self
    }
}
