//
//  UnlockAccessPointViewModel.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import SwiftUI
import BrivoCore
import BrivoBLE
import BrivoOnAir
import BrivoAccess

class UnlockAccessPointViewModel: ObservableObject {
    // MARK: - Properties

    let selectedAccessPoint: BrivoSelectedAccessPoint?
    @Published var isShowingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLocked = true
    @Published var isShowingToast = false
    @Published var isShowingLoading = false

    // MARK: - init

    init(selectedAccessPoint: BrivoSelectedAccessPoint? = nil,
         isShowingAlert: Bool = false,
         alertTitle: String = "",
         alertMessage: String = "",
         isLocked: Bool = true) {
        self.selectedAccessPoint = selectedAccessPoint
        self.isShowingAlert = isShowingAlert
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
        self.isLocked = isLocked
    }

    // swiftlint:disable line_length
    // swiftlint:disable function_body_length
    func openAccessPoint() {
        isShowingLoading = true
        setUnlockedTimer()

        let cancellationSignal = CancellationSignal()
        let timer = Timer(timeInterval: 10.0, repeats: false) {[weak self] (timer) in
            cancellationSignal.isCancelled = true
            self?.resetToInitialState()
            timer.invalidate()
        }

        let brivoSDKAccess = BrivoSDKAccess.instance()
        brivoSDKAccess.turnOnCentral()

        if let selectedAccessPoint = selectedAccessPoint {
            let passId = selectedAccessPoint.accessPointPath.passId
            let accessPointIdString = "\(selectedAccessPoint.accessPointPath.accessPointId)"

            unlockSelectedAccessPoint(passId: passId,
                                      accessPointIdString: accessPointIdString,
                                      brivoSDKAccess: brivoSDKAccess,
                                      cancellationSignal: cancellationSignal,
                                      timer: timer)
        } else {
            unlockNearestAccessPoint(brivoSDKAccess: brivoSDKAccess,
                                     cancellationSignal: cancellationSignal,
                                     timer: timer)
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

    // MARK: - Private

    private func unlockSelectedAccessPoint(passId: String,
                                           accessPointIdString: String,
                                           brivoSDKAccess: BrivoSDKAccess,
                                           cancellationSignal: CancellationSignal,
                                           timer: Timer) {
        Task {
            for try await result in await brivoSDKAccess.unlockAccessPoint(passId: passId,
                                                                           accessPointId: accessPointIdString,
                                                                           cancellationSignal: cancellationSignal) {
                await MainActor.run {
                    if result.accessPointCommunicationState == .success {
                        timer.invalidate()
                        self.setLocked(isLocked: false)
                        self.isShowingToast = true
                        isShowingLoading = false
                    } else if result.accessPointCommunicationState == .failed {
                        timer.invalidate()
                        self.resetToInitialState()

                        if let error = result.error {
                            self.alertTitle = "Error"
                            self.alertMessage = (error.localizedDescription) + " " + "Status Code: \(error.code)"
                            self.isShowingAlert = true
                        }
                    }
                }
            }
        }
    }


    private func unlockNearestAccessPoint(brivoSDKAccess: BrivoSDKAccess,
                                          cancellationSignal: CancellationSignal,
                                          timer: Timer) {
        Task {
            for try await result in await brivoSDKAccess.unlockNearestBLEAccessPoint(cancellationSignal: cancellationSignal) {
                await MainActor.run {
                    switch result.accessPointCommunicationState {
                    case .success:
                        timer.invalidate()
                        self.setLocked(isLocked: false)
                        isShowingLoading = false
                    case .failed:
                        timer.invalidate()
                        self.resetToInitialState()
                        self.alertTitle = "Error"
                        self.alertMessage = (result.error?.localizedDescription ?? "") + " " + "Status Code: \(result.error?.code ?? 0)"
                        self.isShowingAlert = true
                    default:
                        break
                    }
                }
            }
        }
    }

    private func resetToInitialState() {
        setLocked(isLocked: true)
        isShowingLoading = false
    }

    private func setLocked(isLocked: Bool) {
        self.isLocked = isLocked
    }

    private func setUnlockedTimer() {
        let timer = Timer(timeInterval: 30.0, repeats: false) {[weak self] (timer) in
            self?.setLocked(isLocked: true)
            timer.invalidate()
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}
