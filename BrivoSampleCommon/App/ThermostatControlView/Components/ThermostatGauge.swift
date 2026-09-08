//
//  ThermostatGauge.swift
//  BrivoSampleApp
//

import SwiftUI

struct ThermostatGauge: View {
    enum Mode: Equatable {
        case cool
        case heat
        case range
        case off
    }

    let mode: Mode
    let currentTemperature: Double
    let lowTemperature: Double
    let highTemperature: Double
    let temperatureRange: ClosedRange<Double>
    let configuration: ThermostatConfiguration
    let isEnabled: Bool
    let onLowTemperatureChanged: (Double) -> Void
    let onHighTemperatureChanged: (Double) -> Void

    private let startAngle: Double = 135
    private let endAngle: Double = 405

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let rect = CGRect(
                x: (proxy.size.width - size) / 2,
                y: (proxy.size.height - size) / 2,
                width: size,
                height: size
            )
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = (size / 2) - 34

            ZStack {
                ThermostatArc(startAngle: .degrees(startAngle), endAngle: .degrees(endAngle))
                    .stroke(Color(.brivoNeutral).opacity(0.16),
                            style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: size - 36, height: size - 36)
                    .position(center)

                ThermostatArc(startAngle: .degrees(startAngle), endAngle: .degrees(endAngle))
                    .stroke(gaugeGradient,
                            style: StrokeStyle(lineWidth: 28, lineCap: .round))
                    .frame(width: size - 36, height: size - 36)
                    .position(center)
                    .opacity(isEnabled ? 1 : 0.48)

                marker(for: lowTemperature, center: center, radius: radius)
                    .opacity(lowMarkerOpacity)

                marker(for: highTemperature, center: center, radius: radius)
                    .opacity(highMarkerOpacity)

                centerContent
                    .padding(.horizontal, 40)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        guard isEnabled else { return }
                        guard isOnRing(gesture.location, center: center, radius: radius) else { return }
                        handleDrag(at: gesture.location, center: center)
                    }
            )
        }
        .frame(minHeight: 296, maxHeight: 316)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityIds.Thermostat.gauge)
    }

    private var gaugeGradient: LinearGradient {
        LinearGradient(colors: gaugeColors, startPoint: .leading, endPoint: .trailing)
    }

    private var gaugeColors: [Color] {
        guard isEnabled else {
            return [Color(.brivoNeutral).opacity(0.45), Color(.brivoNeutral)]
        }

        switch mode {
        case .cool:
            return [Color(.brivoBlue).opacity(0.42), Color(.brivoBlue)]
        case .heat:
            return [Color(.brivoRed).opacity(0.42), Color(.brivoRed)]
        case .range:
            return [Color(.brivoBlue), Color(.brivoNeutral).opacity(0.6), Color(.brivoRed)]
        case .off:
            return [Color(.brivoNeutral).opacity(0.36), Color(.brivoNeutral)]
        }
    }

    private var lowMarkerOpacity: Double {
        switch mode {
        case .heat, .range:
            return 1
        case .cool, .off:
            return 0
        }
    }

    private var highMarkerOpacity: Double {
        switch mode {
        case .cool, .range:
            return 1
        case .heat, .off:
            return 0
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        if mode == .off {
            Text("--")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .accessibilityLabel("Thermostat is off")
        } else {
            VStack(spacing: 10) {
                Text("Currently")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(configuration.displayNumber(currentTemperature, showsTrailingZero: true))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .minimumScaleFactor(0.72)
                    Text("°\(configuration.displayUnit)")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
            }
        }
    }

    private func marker(for value: Double, center: CGPoint, radius: Double) -> some View {
        let point = point(forProgress: progress(for: value), center: center, radius: radius)
        let labelPoint = markerLabelPoint(for: value, center: center, radius: radius)
        return ZStack {
            Text(configuration.displayNumber(value))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .position(labelPoint)

            Capsule()
                .fill(Color(uiColor: .systemBackground))
                .frame(width: 12, height: 48)
                .overlay {
                    Capsule()
                        .stroke(Color(.brivoNeutral).opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                .rotationEffect(.degrees(markerRotation(for: value)))
                .position(point)
        }
    }

    private func handleDrag(at location: CGPoint, center: CGPoint) {
        let newValue = value(for: location, center: center)
        switch mode {
        case .heat:
            onLowTemperatureChanged(newValue)
        case .cool:
            onHighTemperatureChanged(newValue)
        case .range:
            let isCloserToLow = abs(newValue - lowTemperature) <= abs(newValue - highTemperature)
            if isCloserToLow {
                onLowTemperatureChanged(newValue)
            } else {
                onHighTemperatureChanged(newValue)
            }
        case .off:
            break
        }
    }

    private func point(forProgress progress: Double, center: CGPoint, radius: Double) -> CGPoint {
        let degrees = startAngle + ((endAngle - startAngle) * progress)
        let radians = degrees * .pi / 180
        return CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }

    private func markerLabelPoint(for value: Double, center: CGPoint, radius: Double) -> CGPoint {
        let progress = progress(for: value)
        let degrees = startAngle + ((endAngle - startAngle) * progress)
        let radians = degrees * .pi / 180
        let labelRadius = radius + 38
        return CGPoint(
            x: center.x + cos(radians) * labelRadius,
            y: center.y + sin(radians) * labelRadius
        )
    }

    private func markerRotation(for value: Double) -> Double {
        let progress = progress(for: value)
        let degrees = startAngle + ((endAngle - startAngle) * progress)
        return degrees - 90
    }

    private static let deadZoneRadiusFraction: Double = 0.6

    private func isOnRing(_ location: CGPoint, center: CGPoint, radius: Double) -> Bool {
        hypot(location.x - center.x, location.y - center.y) > radius * Self.deadZoneRadiusFraction
    }

    private func value(for location: CGPoint, center: CGPoint) -> Double {
        let radians = atan2(location.y - center.y, location.x - center.x)
        var degrees = radians * 180 / .pi
        if degrees < 0 {
            degrees += 360
        }
        let clampedDegrees = clampedGaugeDegrees(from: degrees)
        let progress = (clampedDegrees - startAngle) / (endAngle - startAngle)
        let rawValue = temperatureRange.lowerBound + ((temperatureRange.upperBound - temperatureRange.lowerBound) * progress)
        return configuration.serverValue(from: rawValue)
    }

    private func clampedGaugeDegrees(from degrees: Double) -> Double {
        let endAngleOnCircle = endAngle.truncatingRemainder(dividingBy: 360)
        if degrees > endAngleOnCircle, degrees < startAngle {
            let distanceToStart = startAngle - degrees
            let distanceToEnd = degrees - endAngleOnCircle
            return distanceToStart <= distanceToEnd ? startAngle : endAngle
        }

        if degrees < startAngle {
            return degrees + 360
        }

        return min(max(degrees, startAngle), endAngle)
    }

    private func progress(for value: Double) -> Double {
        guard temperatureRange.upperBound > temperatureRange.lowerBound else {
            return 0
        }
        let clampedValue = min(max(value, temperatureRange.lowerBound), temperatureRange.upperBound)
        return (clampedValue - temperatureRange.lowerBound) / (temperatureRange.upperBound - temperatureRange.lowerBound)
    }
}

private struct ThermostatArc: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
