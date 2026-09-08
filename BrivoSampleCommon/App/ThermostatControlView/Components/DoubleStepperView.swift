//
//  DoubleStepperView.swift
//  BrivoSampleApp
//

import SwiftUI

struct DoubleStepperView: View {
    let lowStepperData: StepperData
    let highStepperData: StepperData
    let onLowDecrement: @MainActor () -> Void
    let onLowIncrement: @MainActor () -> Void
    let onHighDecrement: @MainActor () -> Void
    let onHighIncrement: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                makeStepper(
                    data: lowStepperData,
                    tint: Color(.brivoRed),
                    onDecrement: onLowDecrement,
                    onIncrement: onLowIncrement
                )
                makeStepper(
                    data: highStepperData,
                    tint: Color(.brivoBlue),
                    onDecrement: onHighDecrement,
                    onIncrement: onHighIncrement
                )
            }
            if let hint = lowStepperData.hint ?? highStepperData.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
    }

    private func makeStepper(
        data: StepperData,
        tint: Color,
        onDecrement: @escaping @MainActor () -> Void,
        onIncrement: @escaping @MainActor () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Button {
                onIncrement()
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(!data.canIncrement)
            .accessibilityLabel(data.incrementAccessibilityLabel)

            VStack(spacing: 4) {
                Text(data.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .textCase(.uppercase)
                Text(data.value)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .minimumScaleFactor(0.72)
                    .lineLimit(1)
            }
            .frame(width: 108)

            Button {
                onDecrement()
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(!data.canDecrement)
            .accessibilityLabel(data.decrementAccessibilityLabel)
        }
        .frame(maxWidth: .infinity)
    }
}
