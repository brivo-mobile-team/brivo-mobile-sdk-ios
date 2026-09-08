//
//  StepperData.swift
//  BrivoSampleApp
//

struct StepperData: Equatable, Sendable {
    let title: String
    let value: String
    let decrementAccessibilityLabel: String
    let incrementAccessibilityLabel: String
    let canDecrement: Bool
    let canIncrement: Bool
    let hint: String?
}
