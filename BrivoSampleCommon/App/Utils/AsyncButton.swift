//
//  AsyncButton.swift
//  BrivoSampleDev
//
//  Created by Catalin Demian on 28.08.2025.
//

import SwiftUI

struct AsyncButton<Label: View, Loading: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label
    @ViewBuilder var loadingView: () -> Loading
    @State private var isLoading = false

    var body: some View {
        Button(
            action: {
                isLoading = true
                Task { @MainActor in
                    await action()
                    isLoading = false
                }
            },
            label: {
                HStack {
                    label()
                        .overlay {
                            if isLoading {
                                loadingView()
                                    .padding(4)
                                    .background(.thinMaterial)
                                    .cornerRadius(6)
                            }
                        }
                }
                
            }
        )
        .disabled(isLoading)
    }
}

#Preview {
    AsyncButton(action: {
        try? await Task.sleep(for: .seconds(2))
    }, label: {
        Text("Submit")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }, loadingView: {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .frame(width: 24, height: 24)
    })
    .padding()
}
