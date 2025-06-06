//
//  HIDOrigoFooterView.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import SwiftUI
import _PassKit_SwiftUI

struct HIDOrigoFooterView: View {

    let passItem: BrivoOnAirPassListItem
    var addToWalletAction: (() -> Void)

    var body: some View {
        HStack {
            Text("HID ORIGO WALLET: ")
            switch passItem.hidNFCAddToWalletStatus {
            case .ineligible(let reason):
                Text(reason)
            case .eligible:
                AddPassToWalletButton {
                    Task {
                        addToWalletAction()
                    }
                }
                .addPassToWalletButtonStyle(.blackOutline)
            }
        }
    }
}
