//
//  InfoRow.swift
//  BrivoSampleDev
//
//  Created by Denisa Suciu on 04.09.2025.
//

import SwiftUI
import _PassKit_SwiftUI

struct InfoRow: View {

    //MARK: - Properties

    let key: String
    let value: String?
    @Binding var showToast: Bool

    //MARK: - Body

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "-")
                .multilineTextAlignment(.trailing)
                .onTapGesture {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = value
                    showToast = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
        .accessibilityLabel(Text("\(key), \(value ?? "-")"))
    }
}
