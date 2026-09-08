//
//  ThermostatModePickerViewModel.swift
//  BrivoSampleApp
//

import Observation

struct ThermostatPickerOption: Equatable, Identifiable, Sendable {
    let rawValue: String
    let title: String
    let iconName: String

    var id: String {
        rawValue
    }
}

@MainActor
@Observable
final class ThermostatPickerViewModel {
    let title: String
    let accessibilityIdentifier: String
    private(set) var options: [ThermostatPickerOption]
    private(set) var selectedRawValue: String
    var loadingRawValue: String?

    @ObservationIgnored private let onSelection: (ThermostatPickerOption) -> Void

    init(
        allowedModes: [String],
        selectedRawValue: String,
        onSelection: @escaping (ThermostatPickerOption) -> Void
    ) {
        self.title = "Mode"
        self.accessibilityIdentifier = AccessibilityIds.Thermostat.modePicker
        self.options = makeModeOptions(allowedModes: allowedModes, selectedRawValue: selectedRawValue)
        self.selectedRawValue = selectedRawValue.uppercased()
        self.onSelection = onSelection
    }

    init(
        allowedFanModes: [String],
        selectedRawValue: String?,
        onSelection: @escaping (ThermostatPickerOption) -> Void
    ) {
        self.title = "Fan"
        self.accessibilityIdentifier = AccessibilityIds.Thermostat.fanPicker
        self.options = makeFanModeOptions(allowedModes: allowedFanModes, selectedRawValue: selectedRawValue)
        self.selectedRawValue = selectedRawValue?.uppercased() ?? ""
        self.onSelection = onSelection
    }

    func select(_ option: ThermostatPickerOption) {
        guard loadingRawValue == nil else { return }
        guard option.rawValue != selectedRawValue else { return }
        loadingRawValue = option.rawValue
        onSelection(option)
    }

    func update(selectedRawValue: String?) {
        self.selectedRawValue = selectedRawValue?.uppercased() ?? ""
        loadingRawValue = nil
    }

    func stopLoading() {
        loadingRawValue = nil
    }
}

private func makeModeOptions(
    allowedModes: [String],
    selectedRawValue: String
) -> [ThermostatPickerOption] {
    let values = allowedModes.isEmpty ? ThermostatControlMode.allCases.map(\.rawValue) : allowedModes
    var seenValues = Set<String>()
    var uniqueValues = values.compactMap { rawValue -> String? in
        let normalizedValue = rawValue.uppercased()
        guard seenValues.insert(normalizedValue).inserted else { return nil }
        return normalizedValue
    }
    let selectedValue = selectedRawValue.uppercased()
    if !seenValues.contains(selectedValue) {
        uniqueValues.append(selectedValue)
    }
    return uniqueValues.compactMap { rawValue in
        guard let mode = ThermostatControlMode(rawValue: rawValue) else { return nil }
        return ThermostatPickerOption(rawValue: mode.rawValue, title: mode.title, iconName: mode.iconName)
    }
}

private func makeFanModeOptions(
    allowedModes: [String],
    selectedRawValue: String?
) -> [ThermostatPickerOption] {
    var seenValues = Set<String>()
    var uniqueValues = allowedModes.compactMap { rawValue -> String? in
        let normalizedValue = rawValue.uppercased()
        guard seenValues.insert(normalizedValue).inserted else { return nil }
        return normalizedValue
    }
    if let selectedRawValue {
        let selectedValue = selectedRawValue.uppercased()
        if !seenValues.contains(selectedValue) {
            uniqueValues.append(selectedValue)
        }
    }
    return uniqueValues.compactMap { rawValue in
        guard let fanMode = ThermostatControlFanMode(value: rawValue) else { return nil }
        return ThermostatPickerOption(rawValue: fanMode.rawValue, title: fanMode.title, iconName: fanMode.iconName)
    }
}
