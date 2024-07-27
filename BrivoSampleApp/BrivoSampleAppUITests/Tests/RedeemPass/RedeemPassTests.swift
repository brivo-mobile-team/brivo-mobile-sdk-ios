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
    let passesScreenTests = PassesScreenTests()
    var mobilePass: MobilePass?

    // MARK: - Setup&Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        await revokePass()
    }

    // MARK: - Tests

//    func test_ManualRedeemPass() async {
//        await redeemPassManually()
//    }

    // MARK: - Private

    private func redeemPassManually() async {
        do {
            let mobilePass = try await generatePassUseCase.execute()
            await checkManualRedeem(mobilePass: mobilePass)
            try await revokePassUseCase.execute(credentialId: mobilePass.credentialId)
        } catch {
            XCTFail("Could not generate mobile pass")
        }
    }

    private func checkManualRedeem(mobilePass: MobilePass) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.tapOnEnterInviteCode()
                self.passesScreenTests.enterInviteCode(redeemCredentials: mobilePass)
                self.checkConfirmationPopUpScreen()
                continuation.resume()
            }
        }
    }

    private func checkConfirmationPopUpScreen() {
        passesScreenTests.validateAccessPointsLoaded()
    }

    private func revokePass() async {
        guard let mobilePass = mobilePass else {
            return
        }
        do {
            try await revokePassUseCase.execute(credentialId: mobilePass.credentialId)
        } catch {
            print("Could not revoke pass")
        }
    }

    private func tapOnEnterInviteCode() {
        passesScreenTests.openBottomSheet()
    }
}
