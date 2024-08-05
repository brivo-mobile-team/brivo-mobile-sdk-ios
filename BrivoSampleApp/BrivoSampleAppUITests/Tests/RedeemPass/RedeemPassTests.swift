//
//  RedeemPassTests.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 19.04.2024.
//

import Foundation
import XCTest
import BrivoNetworkCore
import BrivoCore

class RedeemPassTests: BaseTest {

    // MARK: - Properties

    lazy var safariApp = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
    lazy var generatePassUseCase = DefaultGeneratePassUseCase()
    lazy var revokePassUseCase = DefaultRevokePassUseCase()
    lazy var cleanupPassUseCase = DefaultCleanupPassUseCase()
    lazy var passesScreen = PassesScreen()
    var mobilePass: MobilePass?

    // MARK: - Setup&Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await cleanupPassUseCase.execute()
    }

    // MARK: - Tests

    func testManualRedeemPass() async {
        await redeemPassManually()
    }

    func testRefreshPass() async {
        await redeemPassManually()
        await checkNoPassesAvailable()
    }

    // MARK: - Private

    private func redeemPassManually() async {
        do {
            let mobilePass = try await generatePassUseCase.execute()
            await checkManualRedeem(mobilePass: mobilePass)
            try await revokePassUseCase.execute(credentialId: mobilePass.credentialId)
        } catch let error {
            XCTFail("Could not generate mobile pass: \(error.localizedDescription)")
        }
    }

    private func checkManualRedeem(mobilePass: MobilePass) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.tapOnEnterInviteCode()
                self.passesScreen.enterInviteCode(redeemCredentials: mobilePass)
                self.validateAccessPointsLoaded()
                continuation.resume()
            }
        }
    }

    private func checkNoPassesAvailable() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.passesScreen.putAppToBackground()
                self.passesScreen.getAppInForeground()
                self.validateNoPassesLoaded()
                continuation.resume()
            }
        }
    }

    private func validateAccessPointsLoaded() {
        passesScreen.validateAccessPointsLoaded()
    }

    private func validateNoPassesLoaded() {
        passesScreen.validateNoPassesLoaded()
    }

    private func tapOnEnterInviteCode() {
        passesScreen.openBottomSheet()
    }
}
