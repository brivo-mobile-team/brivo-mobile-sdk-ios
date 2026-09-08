//
//  ThermostatSyncHandler.swift
//  BrivoSampleApp
//

import BrivoCore
import BrivoOnAir
import Foundation

struct ThermostatSettingsUpdateCommand: Equatable, Sendable {
    let mode: String
    let fanMode: String?
    let heatSetpoint: Double
    let coolSetpoint: Double

    var requestBody: BrivoThermostatUpdateSettingsBody {
        BrivoThermostatUpdateSettingsBody(
            mode: mode,
            fanMode: fanMode,
            heatSetpoint: heatSetpoint,
            coolSetpoint: coolSetpoint
        )
    }
}

struct ThermostatSyncResult: Equatable {
    let command: ThermostatSettingsUpdateCommand
}

protocol ThermostatSyncHandling {
    func getSettings() async -> Result<BrivoThermostatResponse, BrivoError>
    func updateSettings(command: ThermostatSettingsUpdateCommand) async -> Result<ThermostatSyncResult, BrivoError>
}

final class DefaultThermostatSyncHandler: ThermostatSyncHandling, @unchecked Sendable {
    private let brivoTokens: BrivoTokens?
    private let ilAccountIntegrationId: Int
    private let deviceObjectId: Int
    private let brivoOnAir: BrivoSDKOnAir?

    init(
        brivoTokens: BrivoTokens?,
        ilAccountIntegrationId: Int,
        deviceObjectId: Int
    ) {
        self.brivoTokens = brivoTokens
        self.ilAccountIntegrationId = ilAccountIntegrationId
        self.deviceObjectId = deviceObjectId
        self.brivoOnAir = try? BrivoSDKOnAir.instance()
    }

    func getSettings() async -> Result<BrivoThermostatResponse, BrivoError> {
        guard let brivoTokens else {
            return .failure(missingTokensError)
        }
        guard let brivoOnAir else {
            return .failure(unavailableSDKError)
        }

        return await brivoOnAir.getBrivoThermostatSettings(
            brivoTokens: brivoTokens,
            ilAccountIntegrationId: ilAccountIntegrationId,
            deviceObjectId: deviceObjectId
        )
    }

    func updateSettings(command: ThermostatSettingsUpdateCommand) async -> Result<ThermostatSyncResult, BrivoError> {
        guard let brivoTokens else {
            return .failure(missingTokensError)
        }
        guard let brivoOnAir else {
            return .failure(unavailableSDKError)
        }

        let result = await brivoOnAir.setBrivoThermostatSettings(
            brivoTokens: brivoTokens,
            ilAccountIntegrationId: ilAccountIntegrationId,
            deviceObjectId: deviceObjectId,
            body: command.requestBody
        )
        return result.map { ThermostatSyncResult(command: command) }
    }
}

private var missingTokensError: BrivoError {
    BrivoError(
        domain: "ThermostatControlView",
        code: -1,
        description: "Missing OnAir tokens."
    )
}

private var unavailableSDKError: BrivoError {
    BrivoError(
        domain: "ThermostatControlView",
        code: -2,
        description: "BrivoSDKOnAir is not configured."
    )
}

actor Debouncer {
    private var task: Task<Void, Never>?

    func debounce(delayNanoseconds: UInt64 = 2_000_000_000, operation: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
