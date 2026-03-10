//
//  ActivityIndicator.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 12.09.2024.
//

import SwiftUI

// https://medium.com/@davidhu-sg/activity-indicator-with-swiftui-modifier-5234b033d39a

struct ActivityIndicator: UIViewRepresentable {

    // MARK: - Properties

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    // MARK: - ActivityIndicator

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    // swiftlint:disable void_function_in_ternary
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
    // swiftlint:enable void_function_in_ternary
}

struct ActivityIndicatorModifier: AnimatableModifier {

    // MARK: - Properties

    var isLoading: Bool

    // MARK: - Init

    init(isLoading: Bool, color: Color = .primary, lineWidth: CGFloat = 3) {
        self.isLoading = isLoading
    }

    // MARK: - ActivityIndicatorModifier

    var animatableData: Bool {
        get { isLoading }
        set { isLoading = newValue }
    }

    func body(content: Content) -> some View {
        content
            .disabled(isLoading)
            .blur(radius: isLoading ? 3 : 0)
            .overlay {
                if isLoading {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                        .frame(width: 80, height: 80)
                        .background(Color.secondary.colorInvert())
                        .foregroundColor(Color.primary)
                        .cornerRadius(20)
                        .opacity(self.isLoading ? 1 : 0)
                }
            }
    }
}
