//
//  Configuration.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 09.09.2024.
//

import BrivoCore
import Foundation

struct Configuration {
    static let `default` = Configuration()

    var clientId: String = ""
    var clientSecret: String = ""

    var brivoOnAirAuth: String? = nil // most usage scenarios don't need a value for this property.
    var brivoOnAirAPI: String? = nil // most usage scenarios don't need a value for this property

    let dormakabaMobileAppID: Int = 0
    let dormakabaUserName: String = ""
    let dormakabaPassword: String = ""
    let dormakabaServerURL: String = ""
    let dormakabaEvoloSmartProjectID: Int? = nil
    let dormakabaUnlockTimeoutDuration: TimeInterval = 30
}
