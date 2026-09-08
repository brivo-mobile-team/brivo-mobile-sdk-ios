//
//  ThermostatConfiguration.swift
//  BrivoSampleApp
//

import Foundation

struct ThermostatConfiguration: Equatable, Sendable {
    enum Units: String, Sendable {
        case celsius = "CELSIUS"
        case fahrenheit = "FAHRENHEIT"
    }

    let units: Units?

    init(unitsValue: String?) {
        self.units = unitsValue.flatMap { Units(rawValue: $0.uppercased()) }
    }

    var stepSize: Double {
        units == .celsius ? 0.5 : 1.0
    }

    var displayUnit: String {
        units == .celsius ? "C" : "F"
    }

    func serverValue(from value: Double) -> Double {
        let steppedValue = (value / stepSize).rounded() * stepSize
        return roundedValue(steppedValue)
    }

    func displayValue(_ value: Double) -> String {
        guard units != nil else { return displayNumber(value) }
        return "\(displayNumber(value))°\(displayUnit)"
    }

    func displayNumber(_ value: Double, showsTrailingZero: Bool = false) -> String {
        let rounded = roundedValue(value)
        let isWholeNumber = rounded.truncatingRemainder(dividingBy: 1.0) == 0
        if showsTrailingZero {
            return String(format: "%.1f", rounded)
        }
        if isWholeNumber {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", rounded)
    }

    private func roundedValue(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
