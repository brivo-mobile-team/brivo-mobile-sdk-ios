//
//  ThermostatModePickerView.swift
//  BrivoSampleApp
//

import SwiftUI

struct ThermostatModePickerView: View {
    private let viewModel: ThermostatPickerViewModel
    private let onClose: () -> Void

    init(viewModel: ThermostatPickerViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.brivoNeutral).opacity(0.38))
                .frame(width: 42, height: 5)
                .padding(.top, 12)

            Text(viewModel.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)

            HStack(spacing: 18) {
                ForEach(viewModel.options) { option in
                    makeOptionButton(option)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.top, 34)

            Divider()
                .padding(.horizontal, 30)
                .padding(.top, 34)

            Button {
                onClose()
            } label: {
                Text("Close")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(.brivoAccent))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .accessibilityIdentifier(viewModel.accessibilityIdentifier)
    }

    private func makeOptionButton(_ option: ThermostatPickerOption) -> some View {
        let isSelected = option.rawValue == viewModel.selectedRawValue
        let isLoading = option.rawValue == viewModel.loadingRawValue

        return Button {
            viewModel.select(option)
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(optionBackgroundColor(isSelected: isSelected))
                        .frame(width: 62, height: 62)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Image(systemName: option.iconName)
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(isSelected ? Color(.brivoAccent) : Color.secondary)
                    }
                }
                Text(option.title)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(width: 68)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.loadingRawValue != nil)
    }

    private func optionBackgroundColor(isSelected: Bool) -> Color {
        if isSelected {
            return Color(.brivoAccent).opacity(0.24)
        }
        return Color(uiColor: .systemGroupedBackground)
    }
}
