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

struct UnlockAccessPointView: View {
    // MARK: - Properties

    @StateObject var stateModel: UnlockAccessPointViewModel

    // MARK: - Body

    var body: some View {
        Button {
            stateModel.openAccessPoint()
        } label: {
            Image(systemName: stateModel.isLocked ? "lock" : "lock.open")
                .tint(.primary)
            Text(stateModel.isLocked ? "Locked" : "Unlocked")
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
        .toast(message: "Successfully Unlocked!", isShowing: $stateModel.isShowingToast, duration: Toast.long)
        .toast(message: "Tap your phone on the lock", isShowing: $stateModel.isShowingDormakabaToast, duration: Toast.long)
    }
}

#Preview {
    UnlockAccessPointView(stateModel: .init())
}
