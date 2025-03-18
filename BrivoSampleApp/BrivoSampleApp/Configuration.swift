//
//  Configuration.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 09.09.2024.
//

import Foundation
import BrivoCore

struct Configuration {
    static let `default` = Configuration()
    
    var clientId: String = ""
    var clientSecret: String = ""
    
    var brivoOnAirAuth: String? = nil // most usage scenarios don't need a value for this property.
    var brivoOnAirAPI: String? = nil // most usage scenarios don't need a value for this property
}
