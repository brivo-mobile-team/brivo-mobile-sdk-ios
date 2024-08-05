//
//  HomeScreen.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 18.04.2024.
//

import XCTest

class PassesScreen: BaseScreen {

    // MARK: - Properties

    private lazy var openBottomSheetButton = app.buttons[AccessibilityIds.navigationPlusButton]
    private lazy var acountNameTextView = app.staticTexts[AccessibilityIds.accountNameTextView]
    private lazy var noPassesTextView = app.staticTexts[AccessibilityIds.noPassesTextView]

    lazy var mobilePassEmailField = app.textFields[AccessibilityIds.mobilePassEmailField]
    lazy var mobilePassInviteCodeField = app.textFields[AccessibilityIds.mobilePassInviteCodeField]
    lazy var redeemInviteButton = app.buttons[AccessibilityIds.redeemInviteButton]
    
    // add more elements here
    override var baseElement: XCUIElement? {
        get { openBottomSheetButton }
        set { }
    }

    // MARK: - BaseScreen

    override func validateUILoaded() {
        XCTAssertTrue(openBottomSheetButton.exists)
    }

    // MARK: - Public

    func openBottomSheet() {
        openBottomSheetButton.tap()
    }
    
    func validateAccessPointsLoaded() {
        acountNameTextView.waitForExistence()
        XCTAssertTrue(acountNameTextView.exists)
    }

    func validateNoPassesLoaded() {
        noPassesTextView.waitForExistence()
        XCTAssertTrue(noPassesTextView.exists)
    }

    func enterInviteCode(redeemCredentials: MobilePass) {
        mobilePassEmailField.tap()
        mobilePassEmailField.typeText(redeemCredentials.referenceId)
        mobilePassInviteCodeField.tap()
        mobilePassInviteCodeField.typeText(redeemCredentials.accessCode)
        redeemInviteButton.tap()
    }
}
