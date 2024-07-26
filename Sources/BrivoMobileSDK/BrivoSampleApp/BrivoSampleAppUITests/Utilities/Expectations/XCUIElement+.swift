//
//  XCUIElement+.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 18.04.2024.
//

import XCTest

extension XCUIElement {
    func waitForExistence(withTimeout timeout: TimeInterval = BaseTest.Constants.defaultWaitTime) {
        XCTAssertTrue(waitForExistence(timeout: timeout), "failed to get element: \(self)")
    }

    func checkForExistence(timeout: Double = BaseTest.Constants.defaultWaitTime) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 1"), object: self )
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
