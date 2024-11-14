//
//  Configuration.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 09.09.2024.
//

import Foundation
import BrivoCore

// swiftlint:disable identifier_name
enum Environment: String, CaseIterable, Codable {
    case production = "Production"
    case qa = "QA"
    case int = "Int"

    private var region: Region? {
        let region = UserDefaultsAccessService().getRegion()
        switch region {
        case 0:
            return .us
        case 1:
            return .eu
        case .none:
            return .us
        case .some:
            return .us
        }
    }
// swiftlint:enable identifier_name

    var brivoOnAirAuth: String {
        switch self {
        case .production:
            return ""
        case .qa:
            return ""
        case .int:
            return ""
        }
    }

    var brivoOnAirAPI: String {
        switch self {
        case .production:
            return ""
        case .qa:
            return ""
        case .int:
            return ""
        }
    }

    var clientId: String {
        switch self {
        case .production:
            return ""
        case .qa:
            return ""
        case .int:
            return ""
        }
    }

    var clientSecret: String {
        switch self {
        case .production:
            return region == .eu ? Constants.EU_CLIENT_SECRET : Constants.CLIENT_SECRET
        case .qa:
            return ""
        case .int:
            return ""
        }
    }
}

class Configuration {
    static let `default` = Configuration()

    var environment: Environment = {
        let environment = UserDefaultsAccessService().getEnvironment()
        return environment ?? .int
    }()
}
