//
//  ThermostatControlViewModel.swift
//  BrivoSampleApp
//

import BrivoOnAir
import Observation

enum ThermostatControlUpdateSource {
    case remoteRefresh
    case localCommand
}

@MainActor
@Observable
final class ThermostatControlViewModel {
    private let brivoOnAirPass: BrivoOnairPass
    private let thermostat: BrivoThermostat
    private var thermostatData: ThermostatControlData
    private var lastConfirmedData: ThermostatControlData
    private let minimumAutoGap: Double = 1

    @ObservationIgnored private let syncHandler: ThermostatSyncHandling
    @ObservationIgnored private let onConfirmedUpdate: @MainActor (ThermostatControlData, ThermostatControlUpdateSource) -> Void
    @ObservationIgnored private let debouncer = Debouncer()
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var lastFailedCommand: ThermostatSettingsUpdateCommand?
    @ObservationIgnored private var pendingSetpointSync: PendingSetpointSync?
    @ObservationIgnored private var syncGeneration = 0
    @ObservationIgnored private let setpointDebounceDelay: UInt64

    var state: ThermostatSettingsState = .idle
    var activeSheet: ThermostatSettingsState.Sheet?
    var alertMessage: String?
    var isAlertPersistent = false

    init(
        brivoOnAirPass: BrivoOnairPass,
        thermostat: BrivoThermostat,
        thermostatData: ThermostatControlData? = nil,
        syncHandler: ThermostatSyncHandling? = nil,
        setpointDebounceDelay: UInt64 = 2_000_000_000,
        onConfirmedUpdate: @escaping @MainActor (ThermostatControlData, ThermostatControlUpdateSource) -> Void = { _, _ in }
    ) {
        self.brivoOnAirPass = brivoOnAirPass
        self.thermostat = thermostat
        self.setpointDebounceDelay = setpointDebounceDelay
        self.onConfirmedUpdate = onConfirmedUpdate
        let thermostatData = thermostatData ?? ThermostatControlData(thermostat: thermostat)
        self.thermostatData = thermostatData
        self.lastConfirmedData = thermostatData
        self.syncHandler = syncHandler ?? DefaultThermostatSyncHandler(
            brivoTokens: brivoOnAirPass.brivoOnairPassCredentials?.tokens,
            ilAccountIntegrationId: thermostatData.ilAccountIntegrationId,
            deviceObjectId: thermostatData.id
        )
    }

    var title: String {
        thermostatData.name
    }

    var hasRetryAction: Bool {
        lastFailedCommand != nil
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        state = .loading

        Task { [weak self] in
            guard let self else { return }
            let result = await syncHandler.getSettings()
            switch result {
            case let .success(response):
                thermostatData = ThermostatControlData(response: response, fallback: thermostat)
                lastConfirmedData = thermostatData
                notifyConfirmedUpdate(source: .remoteRefresh)
                clearAlert()
            case let .failure(error):
                thermostatData = lastConfirmedData
                showAlert(error.localizedDescription.isEmpty ? "Unable to refresh thermostat settings." : error.localizedDescription)
            }
            refreshContentState()
        }
    }

    func showModePicker() {
        guard controlsEnabled else { return }
        let viewModel = ThermostatPickerViewModel(
            allowedModes: thermostatData.allowedModes,
            selectedRawValue: thermostatData.modeValue
        ) { [weak self] option in
            self?.selectMode(option.rawValue)
        }
        activeSheet = .modePicker(viewModel)
    }

    func showFanPicker() {
        guard controlsEnabled, !thermostatData.allowedFanModes.isEmpty else { return }
        let viewModel = ThermostatPickerViewModel(
            allowedFanModes: thermostatData.allowedFanModes,
            selectedRawValue: thermostatData.fanValue
        ) { [weak self] option in
            self?.selectFanMode(option.rawValue)
        }
        activeSheet = .fanPicker(viewModel)
    }

    func dismissModal() {
        activeSheet = nil
    }

    func clearAlert() {
        guard !isAlertPersistent else { return }
        alertMessage = nil
        lastFailedCommand = nil
    }

    func retryLastSync() {
        guard let lastFailedCommand else { return }
        showAlert(nil)
        performImmediateSync(command: lastFailedCommand, dismissesSheetOnSuccess: true)
    }

    func flushPendingSetpointSync() {
        guard let pending = pendingSetpointSync else { return }
        pendingSetpointSync = nil
        // Bump the generation so a debounced task that is about to send this same command fails its
        // pre-write guard in `syncSetpointCommand` and leaves the write to the flush.
        syncGeneration += 1
        let flushGeneration = syncGeneration

        Task {
            await debouncer.cancel()
            await syncSetpointCommand(pending.command, generation: flushGeneration)
        }
    }

    func changeLowTemperature(to value: Double) {
        guard controlsEnabled, thermostatData.mode != .off else { return }
        thermostatData.heat.value = clampedHeatValue(value)
        refreshContentState()
        scheduleSetpointSync()
    }

    func changeHighTemperature(to value: Double) {
        guard controlsEnabled, thermostatData.mode != .off else { return }
        thermostatData.cool.value = clampedCoolValue(value)
        refreshContentState()
        scheduleSetpointSync()
    }

    func decrementHeatSetpoint() {
        changeLowTemperature(to: thermostatData.heat.value - thermostatData.configuration.stepSize)
    }

    func incrementHeatSetpoint() {
        changeLowTemperature(to: thermostatData.heat.value + thermostatData.configuration.stepSize)
    }

    func decrementCoolSetpoint() {
        changeHighTemperature(to: thermostatData.cool.value - thermostatData.configuration.stepSize)
    }

    func incrementCoolSetpoint() {
        changeHighTemperature(to: thermostatData.cool.value + thermostatData.configuration.stepSize)
    }

    // MARK: - Private

    private struct PendingSetpointSync {
        let command: ThermostatSettingsUpdateCommand
        let generation: Int
    }

    private var hasTokens: Bool {
        brivoOnAirPass.brivoOnairPassCredentials?.tokens != nil
    }

    private var controlsEnabled: Bool {
        thermostatData.isAlive && hasTokens
    }

    private func refreshContentState() {
        state = .content(makeContent())
        refreshAvailabilityAlert()
    }

    private func makeContent() -> ThermostatSettingsState.Content {
        ThermostatSettingsState.Content(
            currentTemperature: thermostatData.temperature,
            gaugeMode: controlsEnabled ? thermostatData.mode.gaugeMode : .off,
            lowTemperature: thermostatData.heat.value,
            highTemperature: thermostatData.cool.value,
            temperatureRange: thermostatData.temperatureRange,
            configuration: thermostatData.configuration,
            settingsMode: makeSettingsMode(),
            actionGroup: makeActionGroup(),
            controlsDisabled: !controlsEnabled
        )
    }

    private func makeSettingsMode() -> ThermostatSettingsState.SettingsMode {
        guard controlsEnabled else {
            return .off(headline: thermostatData.isAlive ? "Controls unavailable" : "Thermostat is offline")
        }

        switch thermostatData.mode {
        case .heat:
            return .heat(stepperData: makeHeatStepperData())
        case .cool:
            return .cool(stepperData: makeCoolStepperData())
        case .auto:
            return .range(lowStepperData: makeHeatStepperData(), highStepperData: makeCoolStepperData())
        case .off:
            return .off(headline: "This thermostat is currently off.\nSwitch mode to begin use.")
        }
    }

    private func makeActionGroup() -> ThermostatSettingsState.ThermostatActionGroup {
        ThermostatSettingsState.ThermostatActionGroup(
            mode: ThermostatSettingsState.ActionConfig(
                id: "mode",
                title: "Mode",
                subtitle: thermostatData.mode.title,
                iconName: thermostatData.mode.iconName,
                isEnabled: controlsEnabled,
                isLoading: false,
                action: { [weak self] in self?.showModePicker() }
            ),
            fan: makeFanAction()
        )
    }

    private func makeFanAction() -> ThermostatSettingsState.ActionConfig? {
        guard !thermostatData.allowedFanModes.isEmpty else { return nil }
        return ThermostatSettingsState.ActionConfig(
            id: "fan",
            title: "Fan",
            subtitle: thermostatData.fanMode?.title,
            iconName: thermostatData.fanMode?.iconName ?? "fan",
            isEnabled: controlsEnabled,
            isLoading: false,
            action: { [weak self] in self?.showFanPicker() }
        )
    }

    private func makeHeatStepperData() -> StepperData {
        let value = thermostatData.heat.value
        let step = thermostatData.configuration.stepSize
        let canDecrement = clampedHeatValue(value - step) < value
        let canIncrement = clampedHeatValue(value + step) > value
        // In auto mode the auto-gap constraint can pin heat at its minimum, leaving both buttons
        // disabled with no visual explanation. Surface the reason so the user knows to raise the
        // cool setpoint rather than seeing a frozen, unexplained control.
        let isPinnedByAutoGap = thermostatData.mode == .auto && !canDecrement && !canIncrement
        return StepperData(
            title: "Heat",
            value: thermostatData.configuration.displayNumber(value),
            decrementAccessibilityLabel: "Decrease heat setpoint",
            incrementAccessibilityLabel: "Increase heat setpoint",
            canDecrement: canDecrement,
            canIncrement: canIncrement,
            hint: isPinnedByAutoGap ? "Raise Cool to adjust Heat" : nil
        )
    }

    private func makeCoolStepperData() -> StepperData {
        let value = thermostatData.cool.value
        let step = thermostatData.configuration.stepSize
        return StepperData(
            title: "Cool",
            value: thermostatData.configuration.displayNumber(value),
            decrementAccessibilityLabel: "Decrease cool setpoint",
            incrementAccessibilityLabel: "Increase cool setpoint",
            canDecrement: clampedCoolValue(value - step) < value,
            canIncrement: clampedCoolValue(value + step) > value,
            hint: nil
        )
    }

    private func selectMode(_ rawValue: String) {
        guard controlsEnabled else { return }
        thermostatData.modeValue = rawValue
        enforceAutoGapIfNeeded()
        refreshContentState()
        performImmediateSync(command: thermostatData.updateCommand(), dismissesSheetOnSuccess: true)
    }

    private func selectFanMode(_ rawValue: String) {
        guard controlsEnabled else { return }
        thermostatData.fanValue = rawValue
        refreshContentState()
        performImmediateSync(command: thermostatData.updateCommand(), dismissesSheetOnSuccess: true)
    }

    private func scheduleSetpointSync() {
        let command = thermostatData.updateCommand()
        syncGeneration += 1
        let generation = syncGeneration
        pendingSetpointSync = PendingSetpointSync(command: command, generation: generation)
        Task { [weak self, setpointDebounceDelay] in
            await self?.debouncer.debounce(delayNanoseconds: setpointDebounceDelay) {
                await self?.syncSetpointCommand(command, generation: generation)
            }
        }
    }

    private func syncSetpointCommand(_ command: ThermostatSettingsUpdateCommand, generation: Int) async {
        // Checked before the write, not just after it: a flush on disappear bumps the generation and
        // sends the pending command itself, so a debounced task that already slipped past
        // `debouncer.cancel()` must bail out here rather than issue a duplicate server write.
        guard generation == syncGeneration else { return }
        // Cleared before the await as well. Once the write is on the wire the command is no longer
        // pending, so a later flush finds nothing to send instead of repeating it.
        clearPendingSetpointCommand(generation: generation)

        let result = await syncHandler.updateSettings(command: command)
        guard generation == syncGeneration else { return }
        switch result {
        case .success:
            lastConfirmedData.apply(command)
            thermostatData.apply(command)
            notifyConfirmedUpdate(source: .localCommand)
            clearAlert()
            refreshContentState()
        case let .failure(error):
            thermostatData = lastConfirmedData
            lastFailedCommand = command
            refreshContentState()
            showAlert(error.localizedDescription.isEmpty ? "Failed to change temperature. Try again." : error.localizedDescription)
        }
    }

    private func clearPendingSetpointCommand(generation: Int) {
        if pendingSetpointSync?.generation == generation {
            pendingSetpointSync = nil
        }
    }

    private func performImmediateSync(
        command: ThermostatSettingsUpdateCommand,
        dismissesSheetOnSuccess: Bool
    ) {
        cancelPendingSetpointSync()
        let generation = syncGeneration
        // Strong capture ensures onConfirmedUpdate fires even if the view is dismissed mid-request,
        // so the parent list's stale-refresh protection window is always set on success.
        Task { [self] in
            let result = await syncHandler.updateSettings(command: command)
            guard generation == syncGeneration else { return }
            switch result {
            case .success:
                thermostatData.apply(command)
                lastConfirmedData = thermostatData
                notifyConfirmedUpdate(source: .localCommand)
                clearAlert()
                updatePickerSelection()
                if dismissesSheetOnSuccess {
                    activeSheet = nil
                }
                refreshContentState()
            case let .failure(error):
                thermostatData = lastConfirmedData
                lastFailedCommand = command
                stopPickerLoading()
                refreshContentState()
                showAlert(error.localizedDescription.isEmpty ? "Failed to update thermostat. Try again." : error.localizedDescription)
            }
        }
    }

    private func cancelPendingSetpointSync() {
        pendingSetpointSync = nil
        syncGeneration += 1
        Task { [debouncer] in
            await debouncer.cancel()
        }
    }

    private func updatePickerSelection() {
        switch activeSheet {
        case let .modePicker(viewModel):
            viewModel.update(selectedRawValue: thermostatData.modeValue)
        case let .fanPicker(viewModel):
            viewModel.update(selectedRawValue: thermostatData.fanValue)
        case nil:
            break
        }
    }

    private func notifyConfirmedUpdate(source: ThermostatControlUpdateSource) {
        onConfirmedUpdate(lastConfirmedData, source)
    }

    private func stopPickerLoading() {
        switch activeSheet {
        case let .modePicker(vm), let .fanPicker(vm):
            vm.stopLoading()
        case nil:
            break
        }
    }

    private func refreshAvailabilityAlert() {
        if !thermostatData.isAlive {
            showAlert("Thermostat is offline", isPersistent: true)
        } else if !hasTokens {
            showAlert("Missing OnAir tokens.")
        } else if isAlertPersistent {
            showAlert(nil)
        }
    }

    private func showAlert(_ message: String?, isPersistent: Bool = false) {
        alertMessage = message
        isAlertPersistent = isPersistent
        if message == nil {
            lastFailedCommand = nil
        }
    }

    private func clampedHeatValue(_ value: Double) -> Double {
        let normalizedValue = thermostatData.configuration.serverValue(from: value)
        let maxValue: Double
        if thermostatData.mode == .auto {
            maxValue = min(thermostatData.heat.maxValue, thermostatData.cool.value - minimumAutoGap)
        } else {
            maxValue = thermostatData.heat.maxValue
        }
        let safeMaxValue = max(thermostatData.heat.minValue, maxValue)
        return min(max(normalizedValue, thermostatData.heat.minValue), safeMaxValue)
    }

    private func clampedCoolValue(_ value: Double) -> Double {
        let normalizedValue = thermostatData.configuration.serverValue(from: value)
        let minValue: Double
        if thermostatData.mode == .auto {
            minValue = max(thermostatData.cool.minValue, thermostatData.heat.value + minimumAutoGap)
        } else {
            minValue = thermostatData.cool.minValue
        }
        let safeMinValue = min(thermostatData.cool.maxValue, minValue)
        return min(max(normalizedValue, safeMinValue), thermostatData.cool.maxValue)
    }

    private func enforceAutoGapIfNeeded() {
        guard thermostatData.mode == .auto else { return }
        thermostatData.heat.value = clampedHeatValue(thermostatData.heat.value)
        thermostatData.cool.value = clampedCoolValue(thermostatData.cool.value)
    }
}
