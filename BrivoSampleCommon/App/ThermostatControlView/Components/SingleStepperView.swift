//
//  SingleStepperView.swift
//  BrivoSampleApp
//

import SwiftUI

struct SingleStepperView: View {
    let data: StepperData
    let onDecrement: @MainActor () -> Void
    let onIncrement: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 10) {
            stepperRow
            if let hint = data.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 18, x: 0, y: 10)
    }

    private var stepperRow: some View {
        HStack(spacing: 14) {
            Button {
                onDecrement()
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(!data.canDecrement)
            .accessibilityLabel(data.decrementAccessibilityLabel)

            VStack(spacing: 4) {
                Text(data.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                Text(data.value)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(minWidth: 124)

            Button {
                onIncrement()
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(StepperButtonStyle())
            .disabled(!data.canIncrement)
            .accessibilityLabel(data.incrementAccessibilityLabel)
        }
    }
}
