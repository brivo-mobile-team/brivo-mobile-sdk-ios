//
//  AccessPointViewModel.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import SwiftUI
import BrivoAccess
import BrivoCore
import BrivoOnAir

class AccessPointViewModel {
    // MARK: - Properties

    let brivoOnAirPass: BrivoOnairPass
    var brivoSites: BrivoOnAir.BrivoSite
    private(set) lazy var accessPoints: [BrivoAccessPoint] = {
        brivoSites.accessPoints?.filter { $0.doorType != .hidOrigo } ?? []
    }()
    private(set) lazy var origoAccessPoints: [BrivoAccessPoint] = {
        brivoSites.accessPoints?.filter { $0.doorType == .hidOrigo } ?? []
    }()

    // MARK: - init

    init(brivoOnAirPass: BrivoOnairPass, brivoSites: BrivoOnAir.BrivoSite) {
        self.brivoSites = brivoSites
        self.brivoOnAirPass = brivoOnAirPass
    }
}
