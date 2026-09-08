//
//  ThermostatAlertBanner.swift
//  BrivoSampleApp
//

import SwiftUI

struct ThermostatAlertBanner: View {
    private static let autoDismissDelay: UInt64 = 3_000_000_000

    @Binding var message: String?
    let isPersistent: Bool
    let retryAction: (() -> Void)?

    var body: some View {
        if let message {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color(.brivoRed))
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if let retryAction {
                    Button("Retry") {
                        retryAction()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(.brivoAccent))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.brivoSurface))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.brivoRed).opacity(0.35), lineWidth: 1)
            }
            .accessibilityIdentifier(AccessibilityIds.Thermostat.alertBanner)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task(id: message) {
                guard !isPersistent else { return }
                let visibleMessage = message
                try? await Task.sleep(nanoseconds: Self.autoDismissDelay)
                guard !Task.isCancelled, self.message == visibleMessage else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    self.message = nil
                }
            }
        }
    }
}
