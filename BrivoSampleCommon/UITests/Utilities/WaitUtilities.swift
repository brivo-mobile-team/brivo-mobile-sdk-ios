//
//  WaitUtilities.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 18.04.2024.
//

import XCTest

public func waitUntilElementDisappear(element: XCUIElement, timeOut: Double = BaseTest.TestsConstants.defaultWaitTime) {
    var elementVisible = true
    let startTime = NSDate().timeIntervalSince1970

    while (NSDate().timeIntervalSince1970 - startTime) < timeOut {
        if !element.exists {
            elementVisible = false
            break
        }
        usleep(300_000) // 300ms
    }

    XCTAssertFalse(elementVisible, "\(element) is still visible")
}

extension XCTWaiter {
    static func wait(timeout: Double = BaseTest.TestsConstants.animationWaitTime) {
        let exp = XCTestExpectation(description: "Test after \(timeout) seconds")
        _ = XCTWaiter.wait(for: [exp], timeout: timeout)
    }
}
