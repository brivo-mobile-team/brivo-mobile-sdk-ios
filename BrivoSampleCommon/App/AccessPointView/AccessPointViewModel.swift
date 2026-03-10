//
//  AccessPointViewModel.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import BrivoAccess
import BrivoCore
import BrivoOnAir
import SwiftUI

@Observable
class AccessPointViewModel {
    // MARK: - Properties

    private let brivoOnAirPass: BrivoOnairPass
    private let brivoSite: BrivoSite
    private let formatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.numberStyle = .decimal
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.unitStyle = .medium
        return formatter
    }()

    let siteName: String
    private(set) var accessPointItems: [AccessPointItem] = []
    private(set) var origoAccessPointItems: [AccessPointItem] = []
    private(set) var thermostatItems: [ThermostatItem] = []
    private(set) var siteExtendedDetails: [ExtendedInfoItem] = []
    var shouldShowCopyToast: Bool = false
    var shouldShowBottomSheet: Bool = false

    // MARK: - init

    init(brivoOnAirPass: BrivoOnairPass, brivoSite: BrivoSite) {
        self.brivoSite = brivoSite
        self.brivoOnAirPass = brivoOnAirPass
        self.siteName = brivoSite.siteName ?? "N/A"
        self.accessPointItems = makeAccessPointItems(from: brivoSite)
        self.origoAccessPointItems = makeOrigoAccessPointItems(from: brivoSite)
        self.thermostatItems = makeThermostatItems(from: brivoSite)
        self.siteExtendedDetails = makeSiteExtendedDetails(from: brivoSite)
    }

    func selectedAccessPoint(for accessPointItem: AccessPointItem) -> BrivoSelectedAccessPoint? {
        let accessPoint = accessPointItem.backingData
        guard let userId = brivoOnAirPass.brivoOnairPassCredentials?.userId,
              let passId = brivoOnAirPass.passId
        else {
            return nil
        }
        return BrivoSelectedAccessPoint(
            accessPointPath: AccessPointPath(
                accessPointId: accessPoint.id,
                siteId: accessPoint.siteId,
                passId: passId
            ),
            doorType: accessPoint.getDoorType(from: brivoOnAirPass),
            passCredential: .init(
                userId: userId,
                tokens: brivoOnAirPass.brivoOnairPassCredentials?.tokens
            ),
            isTwoFactorEnabled: accessPoint.twoFactorEnabled,
            readerUid: accessPoint.getReaderUid(from: brivoOnAirPass),
            bleCredentials: brivoOnAirPass.bleCredential,
            timeframe: brivoOnAirPass.bleAuthTimeFrame,
            deviceModelId: accessPoint.controlLockDeviceType,
            controlLockId: accessPoint.controlLockId
        )
    }

    // MARK: - Private

    func makeAccessPointItems(from brivoSite: BrivoSite) -> [AccessPointItem] {
        brivoSite.accessPoints?
            .filter { $0.getDoorType(from: brivoOnAirPass) != .hidOrigo }
            .map { AccessPointItem(id: $0.id, name: $0.name ?? "", bleOpening: $0.bluetoothReader != nil, backingData: $0) } ?? []
    }

    func makeOrigoAccessPointItems(from brivoSite: BrivoSite) -> [AccessPointItem] {
        brivoSite.accessPoints?
            .filter { $0.getDoorType(from: brivoOnAirPass) == .hidOrigo }
            .map { AccessPointItem(id: $0.id, name: $0.name ?? "", bleOpening: $0.bluetoothReader != nil, backingData: $0) } ?? []
    }

    func makeSiteExtendedDetails(from brivoSite: BrivoSite) -> [ExtendedInfoItem] {
        let siteId = String(brivoSite.id)
        let trustedNetwork = brivoSite.hasTrustedNetwork ? "Enabled" : "Disabled"
        let preScreening = brivoSite.preScreening
        let timezone = brivoSite.timeZone
        return [
            ExtendedInfoItem(name: "Site ID", value: siteId),
            ExtendedInfoItem(name: "Trusted Network", value: trustedNetwork),
            ExtendedInfoItem(name: "PreScreening", value: preScreening),
            ExtendedInfoItem(name: "Time Zone", value: timezone),
        ]
    }

    func makeThermostatItems(from brivoSite: BrivoSite) -> [ThermostatItem] {
        brivoSite.thermostats?
            .map {
                let unit = if $0.unitsValue == "CELSIUS" {
                    Measurement(value: $0.temperature, unit: UnitTemperature.celsius)
                } else {
                    Measurement(value: $0.temperature, unit: UnitTemperature.fahrenheit)
                }
                formatter.unitOptions = $0.unitsValue != nil ? .providedUnit : []
                return ThermostatItem(id: $0.id,
                                      name: $0.name,
                                      isOnline: $0.isAlive,
                                      temperature: formatter.string(from: unit),
                                      backingData: $0)
            } ?? []
    }
}

struct AccessPointItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let bleOpening: Bool
    let backingData: BrivoAccessPoint
}

struct ThermostatItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let isOnline: Bool
    let temperature: String
    let backingData: BrivoThermostat
}
