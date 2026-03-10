//
//  ExtendedInfoSheet.swift
//  BrivoSampleDev
//
//  Created by Denisa Suciu on 04.09.2025.
//

import SwiftUI

struct ExtendedInfoSheet: View {
    
    //MARK: - Properties

    let title: String
    let items: [ExtendedInfoItem]
    @State var showToast: Bool = false
    
    //MARK: - Body

    var body: some View {
        List {
            ForEach(items, id: \.name) { info in
                InfoRow(key: info.name, value: info.value, showToast: $showToast)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        
        .toast(
            message: "Copied to clipboard",
            isShowing: $showToast,
            duration: Toast.short
        )
        .presentationDetents([.medium])
    }
}
