//
//  BaseTest.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 16.04.2024.
//

import XCTest

open class BaseTest: XCTestCase {

    // MARK: - Properties

    private var baseScreen = BaseScreen()

    public enum TestsConstants {
        public static let animationWaitTime = 2.0
        public static let defaultWaitTime = 5.0
        public static let networkWaitTime = 10.0
    }

    lazy var app = baseScreen.app

    // MARK: - Setup&Teardown

    open override func setUpWithError() throws {
        app.launchArguments = ["enable-testing"]
        app.launch()
    }

    open override func tearDownWithError() throws {
        app.terminate()
    }
}
