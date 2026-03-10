//
//  HeaderWithInfo.swift
//  BrivoSampleDev
//
//  Created by Denisa Suciu on 04.09.2025.
//

import SwiftUI

struct HeaderWithInfo: View {

    //MARK: - Properties

    let title: String
    var onTap: () -> Void

    //MARK: - Body

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Button(action: onTap) {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel(Text("More \(title) info"))
        }
        .padding(.bottom, 4)
    }
}
