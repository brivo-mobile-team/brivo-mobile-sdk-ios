//
//  StepperButtonStyle.swift
//  BrivoSampleApp
//

import SwiftUI

struct StepperButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 50, height: 50)
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.brivoNeutral).opacity(isEnabled ? 0.45 : 0.18), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && isEnabled ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else {
            return Color(.brivoNeutral).opacity(0.22)
        }
        return isPressed ? Color(.brivoAccent).opacity(0.3) : Color(uiColor: .systemBackground)
    }
}
