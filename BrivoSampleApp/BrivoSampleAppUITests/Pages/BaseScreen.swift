//
//  BaseScreen.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 16.04.2024.
//

import XCTest

protocol BaseScreenInterface {
    var baseElement: XCUIElement? { get }
    func validateUILoaded()
    func waitScreenLoaded()
}

class BaseScreen: BaseScreenInterface {

    // MARK: - Properties

    lazy var app = XCUIApplication()

    // MARK: - Init

    init() {
        waitScreenLoaded()
    }

    // MARK: - BaseScreenInterface

    lazy var baseElement: XCUIElement? = nil

    func validateUILoaded() {}

    func waitScreenLoaded() {
        guard let baseElement = baseElement else {
            return
        }
        baseElement.waitForExistence()
    }
}
