//
//  AutomationTestsConfiguration.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 16.04.2024.
//

import Foundation

struct RedeemPassConfig {
    let username: String
    let password: String
    let userId: String
    let referenceId: String
}

struct AutomationTestsConfiguration {
    static let redeemPassConfig = RedeemPassConfig(username: "bmp.automation.tests@gmail.com",
                                                   password: "Brivo100",
                                                   userId: "60263499",
                                                   referenceId: "sdk.sample.automation.ios@brivo.com")
    static let accountId = 1861040
    static let grantType = "password"
    static let scope = "openid"
    static let basicAuthBase64 = "WDerz2RAdLj1DBEHFlQpKCaLOp9EmN2B:EQD6YifgIj3QSQX38g-pT5_AM1TrNocdCaocncZlrfHmTp6jIdccBEXekjsY_GvC".toBase64() ?? ""
    static let apiBaseUrl = "https://access.brivo.com/"
    static let loginBaseUrl = "https://login.brivo.com/"
    static let audience = "https://api.brivo.com"
}
