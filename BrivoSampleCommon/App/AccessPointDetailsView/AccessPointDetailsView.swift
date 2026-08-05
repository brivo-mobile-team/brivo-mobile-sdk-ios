//
//  UnlockAccessPointView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI
import BrivoCore
import BrivoBLE
import BrivoOnAir
import BrivoAccess

struct AccessPointDetailsView: View {

    // MARK: - Properties

    @StateObject var stateModel: AccessPointDetailsViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Button {
                stateModel.openAccessPoint()
            } label: {
                HStack {
                    Image(systemName: stateModel.isLocked ? "lock" : "lock.open")
                        .tint(.primary)
                    Text(stateModel.isLocked ? "Locked" : "Unlocked")
                }
                .padding()
            }
            .padding()
            .background(stateModel.isLocked ? .red : .green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .modifier(ActivityIndicatorModifier(isLoading: stateModel.isShowingLoading))
            .alert(isPresented: $stateModel.isShowingAlert) {
                Alert(
                    title: Text(stateModel.alertTitle),
                    message: Text(stateModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            if stateModel.shouldShowInternetUnlockToggle {
                Toggle(isOn: $stateModel.shouldForceInternetUnlock) {
                    Text("Should force internet unlock")
                }
                .padding()
            }
            if let accessPoint = stateModel.selectedAccessPoint {
                AccessPointExtrasView(
                    viewModel: .init(selectedAccessPoint: accessPoint)
                )
            }
        }
        .toast(
            message: "Successfully Unlocked!",
            isShowing: $stateModel.isShowingToast,
            duration: Toast.long
        )
        .toast(
            message: "Tap your phone on the lock",
            isShowing: $stateModel.isShowingDormakabaToast,
            duration: Toast.long
        )
        .toolbar {
            if stateModel.selectedAccessPoint != nil {
                Button {
                    stateModel.shouldShowBottomSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Access Point Informations Button")
            }
        }
        .sheet(isPresented: $stateModel.shouldShowBottomSheet) {
            ExtendedInfoSheet(title: "Access Point Informations", items: stateModel.doorExtendedDetails)
        }
    }
}

#Preview {
    AccessPointDetailsView(stateModel: .init())
}
