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
    static let redeemPassConfig = RedeemPassConfig(username: "constantin.georgiu@brivo.com",
                                                   password: "Brivo100",
                                                   userId: "55221176",
                                                   referenceId: "bmp.sample.automation.ios@brivo.com")
}
