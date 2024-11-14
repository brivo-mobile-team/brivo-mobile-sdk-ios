//
//  XCTestCase+.swift
//  BrivoSampleDevUITests
//
//  Created by Gabriel Dusa on 12.09.2024.
//

import XCTest

extension XCTestCase {
    func waitUntilElementHasFocus(element: XCUIElement,
                                  timeout: TimeInterval = BaseTest.TestsConstants.defaultWaitTime) -> XCUIElement {
        let expectation = expectation(description: "waiting for element \(element) to have focus")
        let timer = Timer(timeInterval: 1, repeats: true) { timer in
            guard element.hasFocus else { return }
            expectation.fulfill()
            timer.invalidate()
        }
        RunLoop.current.add(timer, forMode: .common)
        wait(for: [expectation], timeout: timeout)
        return element
    }
}
