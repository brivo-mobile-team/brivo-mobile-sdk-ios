//
//  AutomationTestsConfiguration.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 16.04.2024.
//

import Foundation

struct AuthenticationCredentials {
    let username: String
    let password: String
}

struct RedeemPassConfig {
    let username: String
    let password: String
    let userId: String
    let referenceId: String
}

struct AutomationTestsConfiguration {
    static let validLogin: AuthenticationCredentials = AuthenticationCredentials(username: "ana-maria.mihai@vspartners.us",
                                                                                 password: "Brivo100")
    static let invalidLogin: AuthenticationCredentials = AuthenticationCredentials(username: "ana-maria55@vspartners.us",
                                                                                 password: "Brivo")
    static let redeemPassConfig = RedeemPassConfig(username: "constantin.georgiu@brivo.com",
                                                   password: "Brivo100",
                                                   userId: "55221176",
                                                   referenceId: "bmpautomation1@gmail.com")

    static let validNFCAccount: AuthenticationCredentials = AuthenticationCredentials(username: "glad.constantin+testing@gmail.com",
                                                                                      password: "Brivo100")
}
