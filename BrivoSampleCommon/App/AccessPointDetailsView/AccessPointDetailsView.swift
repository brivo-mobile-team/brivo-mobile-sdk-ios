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
            Text("State: \(stateModel.unlockState.description)")
                .font(.headline)
                .accessibilityIdentifier(AccessibilityIds.unlockStateLabel)

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

            if stateModel.canCancelUnlock {
                Button(role: .destructive) {
                    stateModel.cancelUnlock()
                } label: {
                    Text("Cancel unlock")
                        .padding()
                }
                .accessibilityIdentifier(AccessibilityIds.cancelUnlockButton)
            }

            AccessPointExtrasView(
                viewModel: .init(selectedAccessPoint: stateModel.selectedAccessPoint)
            )

            if stateModel.shouldShowInternetUnlockToggle {
                Toggle(isOn: $stateModel.shouldForceInternetUnlock) {
                    Text("Should force internet unlock")
                }
                .padding()
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
            Button {
                stateModel.shouldShowBottomSheet = true
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Access Point Informations Button")
        }
        .sheet(isPresented: $stateModel.shouldShowBottomSheet) {
            ExtendedInfoSheet(title: "Access Point Informations", items: stateModel.doorExtendedDetails)
        }
    }
}

#Preview {
    AccessPointDetailsView(
        stateModel: .init(
            selectedAccessPoint: BrivoSelectedAccessPoint(
                name: "Testing reader",
                accessPointPath: AccessPointPath(
                    accessPointId: 1,
                    siteId: 1,
                    passId: "1",
                    hasTrustedNetwork: false
                ),
                doorType: .internet,
                passCredential: BrivoOnairPassCredentials(
                    userId: "",
                    tokens: BrivoTokens(
                        accessToken: "",
                        refreshToken: ""
                    )
                ),
                deviceModelId: ""
            )
        )
    )
}
