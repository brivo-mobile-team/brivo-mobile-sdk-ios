//
//  AccessPointViewModel.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import Foundation
import BrivoAccess
import BrivoCore
import BrivoOnAir
import Observation

@MainActor
@Observable
final class AccessPointViewModel {
    // MARK: - Properties

    private let brivoOnAirPass: BrivoOnairPass
    private let brivoSite: BrivoSite
    private let hidOrigoTypes: [DoorType] = [.hidOrigo, .hidOrigoOmnikey]

    let siteName: String
    private(set) var accessPointItems: [AccessPointItem] = []
    private(set) var origoAccessPointItems: [AccessPointItem] = []
    private(set) var thermostatItems: [ThermostatItem] = []
    private(set) var siteExtendedDetails: [ExtendedInfoItem] = []
    var shouldShowCopyToast: Bool = false
    var shouldShowBottomSheet: Bool = false

    private var isRefreshingThermostats = false
    private var lastRefreshDate: Date = .distantPast
    private var recentConfirmedUpdates: [Int: RecentThermostatUpdate] = [:]
    private let refreshProtectionInterval: TimeInterval = 45
    private let refreshThrottleInterval: TimeInterval = 15

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
            name: accessPoint.name ?? "Unknown Access Point",
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

    func makeThermostatControlViewModel(for thermostatItem: ThermostatItem) -> ThermostatControlViewModel {
        ThermostatControlViewModel(
            brivoOnAirPass: brivoOnAirPass,
            thermostat: thermostatItem.backingData,
            thermostatData: thermostatItem.controlData
        ) { [weak self] thermostatData, source in
            self?.updateThermostatItem(
                with: thermostatData,
                protectFromStaleRefresh: source == .localCommand
            )
        }
    }

    func refreshThermostatItems() async {
        let now = Date()
        guard !isRefreshingThermostats,
              !thermostatItems.isEmpty,
              now.timeIntervalSince(lastRefreshDate) > refreshThrottleInterval else { return }

        lastRefreshDate = now
        isRefreshingThermostats = true
        defer { isRefreshingThermostats = false }

        let tokens = brivoOnAirPass.brivoOnairPassCredentials?.tokens
        let snapshot = thermostatItems

        await withTaskGroup(of: ThermostatControlData?.self) { group in
            for item in snapshot {
                let syncHandler = DefaultThermostatSyncHandler(
                    brivoTokens: tokens,
                    ilAccountIntegrationId: item.backingData.ilAccountIntegrationId,
                    deviceObjectId: item.id
                )
                let backingData = item.backingData
                group.addTask {
                    if case let .success(response) = await syncHandler.getSettings() {
                        return ThermostatControlData(response: response, fallback: backingData)
                    }
                    return nil
                }
            }
            for await responseData in group {
                if let responseData {
                    updateThermostatItem(with: responseData)
                }
            }
        }
    }

    // MARK: - Private

    func makeAccessPointItems(from brivoSite: BrivoSite) -> [AccessPointItem] {
        brivoSite.accessPoints?
            .filter { !hidOrigoTypes.contains($0.getDoorType(from: brivoOnAirPass)) }
            .map { AccessPointItem(id: $0.id, name: $0.name ?? "", bleOpening: $0.bluetoothReader != nil, backingData: $0) } ?? []
    }

    func makeOrigoAccessPointItems(from brivoSite: BrivoSite) -> [AccessPointItem] {
        brivoSite.accessPoints?
            .filter { hidOrigoTypes.contains($0.getDoorType(from: brivoOnAirPass)) }
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
            ExtendedInfoItem(name: "Time Zone", value: timezone)
        ]
    }

    func makeThermostatItems(from brivoSite: BrivoSite) -> [ThermostatItem] {
        brivoSite.thermostats?
            .map {
                ThermostatItem(
                    controlData: ThermostatControlData(thermostat: $0),
                    backingData: $0
                )
            } ?? []
    }

    private func updateThermostatItem(
        with thermostatData: ThermostatControlData,
        protectFromStaleRefresh: Bool = false
    ) {
        guard let index = thermostatItems.firstIndex(where: { $0.id == thermostatData.id }) else { return }
        if protectFromStaleRefresh {
            recentConfirmedUpdates[thermostatData.id] = RecentThermostatUpdate(
                data: thermostatData,
                expiresAt: Date().addingTimeInterval(refreshProtectionInterval)
            )
        }
        // Remote refreshes must pass through the protection window so a confirmed local
        // command (e.g. mode change) isn't overwritten by a lagging server response.
        let visibleData = protectFromStaleRefresh ? thermostatData : visibleThermostatData(from: thermostatData)
        // In-place rather than copy-mutate-reassign: the refresh loop calls this once per
        // thermostat, and the temporary second reference forced a full array copy every time.
        thermostatItems[index] = ThermostatItem(
            controlData: visibleData,
            backingData: thermostatItems[index].backingData
        )
    }

    private func visibleThermostatData(from responseData: ThermostatControlData) -> ThermostatControlData {
        guard let recentUpdate = recentConfirmedUpdates[responseData.id] else { return responseData }
        guard recentUpdate.expiresAt > Date() else {
            recentConfirmedUpdates[responseData.id] = nil
            return responseData
        }
        guard !responseData.hasSameSettings(as: recentUpdate.data) else {
            recentConfirmedUpdates[responseData.id] = nil
            return responseData
        }
        // Server hasn't replicated the local command yet — show the locally-confirmed settings,
        // but always propagate live read-only fields so device status changes are not hidden.
        var protected = recentUpdate.data
        protected.isAlive = responseData.isAlive
        protected.temperature = responseData.temperature
        return protected
    }
}

private struct RecentThermostatUpdate {
    let data: ThermostatControlData
    let expiresAt: Date
}

struct AccessPointItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let bleOpening: Bool
    let backingData: BrivoAccessPoint
}

struct ThermostatItem: Identifiable, Equatable {
    let controlData: ThermostatControlData
    let backingData: BrivoThermostat

    var id: Int {
        controlData.id
    }

    var name: String {
        controlData.name
    }

    var isOnline: Bool {
        controlData.isAlive
    }

    var temperature: String {
        controlData.configuration.displayValue(controlData.temperature)
    }

    var modeTitle: String {
        controlData.mode.title
    }
}

private extension ThermostatControlData {
    func hasSameSettings(as other: ThermostatControlData) -> Bool {
        normalized(modeValue) == normalized(other.modeValue)
            && normalized(fanValue) == normalized(other.fanValue)
            && abs(heat.value - other.heat.value) < 0.001
            && abs(cool.value - other.cool.value) < 0.001
    }

    private func normalized(_ value: String?) -> String? {
        value?.uppercased()
    }
}
