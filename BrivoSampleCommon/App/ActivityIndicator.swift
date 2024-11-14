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
        ZStack {
            if isLoading {
                GeometryReader { geometry in
                    ZStack(alignment: .center) {
                        content
                            .disabled(self.isLoading)
                            .blur(radius: self.isLoading ? 3 : 0)

                        VStack {
                            ActivityIndicator(isAnimating: .constant(true), style: .large)
                        }
                        .frame(width: geometry.size.width / 2,
                               height: geometry.size.height / 5)
                        .background(Color.secondary.colorInvert())
                        .foregroundColor(Color.primary)
                        .cornerRadius(20)
                        .opacity(self.isLoading ? 1 : 0)
                        .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
                    }
                }
            } else {
                content
            }
        }
    }
}
