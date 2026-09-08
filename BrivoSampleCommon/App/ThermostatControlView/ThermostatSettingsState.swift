//
//  ThermostatSettingsState.swift
//  BrivoSampleApp
//

import BrivoOnAir
import Foundation

enum ThermostatControlMode: String, CaseIterable, Sendable {
    case cool = "COOL"
    case heat = "HEAT"
    case auto = "AUTO"
    case off = "OFF"

    init(value: String?) {
        switch value?.uppercased() {
        case ThermostatControlMode.cool.rawValue:
            self = .cool
        case ThermostatControlMode.heat.rawValue:
            self = .heat
        case ThermostatControlMode.auto.rawValue:
            self = .auto
        default:
            self = .off
        }
    }

    var title: String {
        switch self {
        case .cool:
            return "Cool"
        case .heat:
            return "Heat"
        case .auto:
            return "Auto"
        case .off:
            return "Off"
        }
    }

    var iconName: String {
        switch self {
        case .cool:
            return "snowflake"
        case .heat:
            return "flame"
        case .auto:
            return "arrow.triangle.2.circlepath"
        case .off:
            return "power"
        }
    }

    var gaugeMode: ThermostatGauge.Mode {
        switch self {
        case .cool:
            return .cool
        case .heat:
            return .heat
        case .auto:
            return .range
        case .off:
            return .off
        }
    }
}

enum ThermostatControlFanMode: String, CaseIterable, Sendable {
    case auto = "AUTO"
    case on = "ON"
    case circulate = "CIRCULATE"

    init?(value: String?) {
        switch value?.uppercased() {
        case ThermostatControlFanMode.auto.rawValue:
            self = .auto
        case ThermostatControlFanMode.on.rawValue:
            self = .on
        case ThermostatControlFanMode.circulate.rawValue:
            self = .circulate
        default:
            return nil
        }
    }

    var title: String {
        switch self {
        case .auto:
            return "Auto"
        case .on:
            return "On"
        case .circulate:
            return "Circulate"
        }
    }

    var iconName: String {
        switch self {
        case .auto:
            return "fan"
        case .on:
            return "fan.fill"
        case .circulate:
            return "arrow.triangle.2.circlepath"
        }
    }
}

struct ThermostatTemperatureSetting: Equatable, Sendable {
    var value: Double
    let minValue: Double
    let maxValue: Double

    init(value: Double, minValue: Double, maxValue: Double) {
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
    }

    init(rangeInfo: BrivoThermostatRangeInfo) {
        self.init(value: rangeInfo.value,
                  minValue: rangeInfo.minValue,
                  maxValue: rangeInfo.maxValue)
    }
}

struct ThermostatControlData: Equatable {
    let id: Int
    let name: String
    let siteId: Int
    let ilAccountIntegrationId: Int
    var temperature: Double
    var modeValue: String
    var allowedModes: [String]
    var fanValue: String?
    var allowedFanModes: [String]
    var unitsValue: String?
    var heat: ThermostatTemperatureSetting
    var cool: ThermostatTemperatureSetting
    var isAlive: Bool

    init(thermostat: BrivoThermostat) {
        self.id = thermostat.id
        self.name = thermostat.name
        self.siteId = thermostat.siteId
        self.ilAccountIntegrationId = thermostat.ilAccountIntegrationId
        self.temperature = thermostat.temperature
        self.modeValue = thermostat.mode.value.isEmpty ? thermostat.modeValue : thermostat.mode.value
        self.allowedModes = thermostat.mode.allowedModes
        self.fanValue = thermostat.fan?.value ?? thermostat.fanValue
        self.allowedFanModes = thermostat.fan?.allowedModes ?? []
        self.unitsValue = thermostat.units?.value ?? thermostat.unitsValue
        self.heat = ThermostatTemperatureSetting(rangeInfo: thermostat.heat)
        self.cool = ThermostatTemperatureSetting(rangeInfo: thermostat.cool)
        self.isAlive = thermostat.isAlive
    }

    init(response: BrivoThermostatResponse, fallback: BrivoThermostat) {
        self.id = fallback.id
        self.name = response.deviceData.name
        self.siteId = fallback.siteId
        self.ilAccountIntegrationId = fallback.ilAccountIntegrationId
        self.temperature = response.deviceState.temperature
        self.modeValue = response.deviceSettings.mode.value
        self.allowedModes = response.deviceSettings.mode.allowedModes
        self.fanValue = response.deviceSettings.fan?.value
        self.allowedFanModes = response.deviceSettings.fan?.allowedModes ?? []
        self.unitsValue = response.deviceSettings.units.value
        self.heat = ThermostatTemperatureSetting(rangeInfo: response.deviceSettings.heat)
        self.cool = ThermostatTemperatureSetting(rangeInfo: response.deviceSettings.cool)
        self.isAlive = response.deviceState.isAlive
    }

    var mode: ThermostatControlMode {
        ThermostatControlMode(value: modeValue)
    }

    var fanMode: ThermostatControlFanMode? {
        ThermostatControlFanMode(value: fanValue)
    }

    var configuration: ThermostatConfiguration {
        ThermostatConfiguration(unitsValue: unitsValue)
    }

    var temperatureRange: ClosedRange<Double> {
        let lower: Double
        let upper: Double
        switch mode {
        case .heat:
            lower = heat.minValue
            upper = heat.maxValue
        case .cool:
            lower = cool.minValue
            upper = cool.maxValue
        case .auto, .off:
            lower = min(heat.minValue, cool.minValue)
            upper = max(heat.maxValue, cool.maxValue)
        }
        return min(lower, upper)...max(lower, upper)
    }

    func updateCommand() -> ThermostatSettingsUpdateCommand {
        ThermostatSettingsUpdateCommand(
            mode: modeValue,
            fanMode: fanValue,
            heatSetpoint: heat.value,
            coolSetpoint: cool.value
        )
    }

    mutating func apply(_ command: ThermostatSettingsUpdateCommand) {
        modeValue = command.mode
        fanValue = command.fanMode
        heat.value = command.heatSetpoint
        cool.value = command.coolSetpoint
    }
}

enum ThermostatSettingsState {
    case idle
    case loading
    case content(Content)
    case error(String)

    struct Content {
        let currentTemperature: Double
        let gaugeMode: ThermostatGauge.Mode
        let lowTemperature: Double
        let highTemperature: Double
        let temperatureRange: ClosedRange<Double>
        let configuration: ThermostatConfiguration
        let settingsMode: SettingsMode
        let actionGroup: ThermostatActionGroup
        let controlsDisabled: Bool
    }

    enum SettingsMode {
        case off(headline: String)
        case heat(stepperData: StepperData)
        case cool(stepperData: StepperData)
        case range(lowStepperData: StepperData, highStepperData: StepperData)
    }

    enum Sheet: Identifiable {
        case modePicker(ThermostatPickerViewModel)
        case fanPicker(ThermostatPickerViewModel)

        var id: String {
            switch self {
            case .modePicker:
                return "modePicker"
            case .fanPicker:
                return "fanPicker"
            }
        }
    }

    struct ThermostatActionGroup {
        let mode: ActionConfig
        let fan: ActionConfig?
    }

    struct ActionConfig: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let iconName: String
        let isEnabled: Bool
        let isLoading: Bool
        let action: @MainActor () -> Void
    }

}
