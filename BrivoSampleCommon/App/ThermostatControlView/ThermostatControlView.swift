//
//  ThermostatControlView.swift
//  BrivoSampleApp
//

import SwiftUI

struct ThermostatControlView: View {
    private static let pickerSheetHeight: CGFloat = 340

    @State private var viewModel: ThermostatControlViewModel

    init(viewModel: ThermostatControlViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case let .content(content):
                contentView(content)
            case let .error(message):
                errorView(message)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.load()
        }
        .onDisappear {
            viewModel.flushPendingSetpointSync()
        }
        .sheet(item: activeSheetBinding) { sheet in
            sheetView(sheet)
                .presentationDetents([.height(Self.pickerSheetHeight)])
                .presentationDragIndicator(.hidden)
        }
        .accessibilityIdentifier(AccessibilityIds.Thermostat.screen)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading thermostat")
                .font(.headline)
                .foregroundStyle(Color.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(.brivoRed))
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
        }
        .padding(24)
    }

    private func contentView(_ content: ThermostatSettingsState.Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    ThermostatAlertBanner(
                        message: alertBinding,
                        isPersistent: viewModel.isAlertPersistent,
                        retryAction: viewModel.hasRetryAction ? { viewModel.retryLastSync() } : nil
                    )
                    .padding(.bottom, viewModel.alertMessage == nil ? 0 : 16)

                    ThermostatGauge(
                        mode: content.gaugeMode,
                        currentTemperature: content.currentTemperature,
                        lowTemperature: content.lowTemperature,
                        highTemperature: content.highTemperature,
                        temperatureRange: content.temperatureRange,
                        configuration: content.configuration,
                        isEnabled: !content.controlsDisabled,
                        onLowTemperatureChanged: { viewModel.changeLowTemperature(to: $0) },
                        onHighTemperatureChanged: { viewModel.changeHighTemperature(to: $0) }
                    )

                    settingsModeView(content.settingsMode)
                        .padding(.horizontal, 16)
                        .padding(.top, 26)
                        .disabled(content.controlsDisabled)
                        .opacity(content.controlsDisabled ? 0.5 : 1)

                    Spacer(minLength: 88)

                    actionGroupView(content.actionGroup)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 42)
                .frame(minHeight: max(geometry.size.height - 18, 0))
            }
        }
    }

    @ViewBuilder
    private func settingsModeView(_ mode: ThermostatSettingsState.SettingsMode) -> some View {
        switch mode {
        case let .off(headline):
            Text(headline)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
        case let .heat(stepperData):
            SingleStepperView(
                data: stepperData,
                onDecrement: { viewModel.decrementHeatSetpoint() },
                onIncrement: { viewModel.incrementHeatSetpoint() }
            )
        case let .cool(stepperData):
            SingleStepperView(
                data: stepperData,
                onDecrement: { viewModel.decrementCoolSetpoint() },
                onIncrement: { viewModel.incrementCoolSetpoint() }
            )
        case let .range(lowStepperData, highStepperData):
            DoubleStepperView(
                lowStepperData: lowStepperData,
                highStepperData: highStepperData,
                onLowDecrement: { viewModel.decrementHeatSetpoint() },
                onLowIncrement: { viewModel.incrementHeatSetpoint() },
                onHighDecrement: { viewModel.decrementCoolSetpoint() },
                onHighIncrement: { viewModel.incrementCoolSetpoint() }
            )
        }
    }

    private func actionGroupView(_ actionGroup: ThermostatSettingsState.ThermostatActionGroup) -> some View {
        HStack(spacing: 72) {
            actionButton(actionGroup.mode)
                .accessibilityIdentifier(AccessibilityIds.Thermostat.modeButton)
            if let fan = actionGroup.fan {
                actionButton(fan)
                    .accessibilityIdentifier(AccessibilityIds.Thermostat.fanButton)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(_ config: ThermostatSettingsState.ActionConfig) -> some View {
        Button {
            config.action()
        } label: {
            VStack(spacing: 12) {
                if config.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: config.iconName)
                        .font(.system(size: 30, weight: .regular))
                        .frame(width: 36, height: 36)
                }
                Text(config.title)
                    .font(.headline.weight(.medium))
            }
            .foregroundStyle(config.isEnabled ? Color.primary : Color.secondary)
            .frame(minWidth: 80)
        }
        .buttonStyle(.plain)
        .disabled(!config.isEnabled)
    }

    @ViewBuilder
    private func sheetView(_ sheet: ThermostatSettingsState.Sheet) -> some View {
        switch sheet {
        case let .modePicker(vm), let .fanPicker(vm):
            ThermostatModePickerView(viewModel: vm, onClose: { viewModel.dismissModal() })
        }
    }

    private var alertBinding: Binding<String?> {
        Binding {
            viewModel.alertMessage
        } set: { message in
            if message == nil {
                viewModel.clearAlert()
            } else {
                viewModel.alertMessage = message
            }
        }
    }

    private var activeSheetBinding: Binding<ThermostatSettingsState.Sheet?> {
        Binding {
            viewModel.activeSheet
        } set: { sheet in
            if sheet == nil {
                viewModel.dismissModal()
            }
        }
    }
}
