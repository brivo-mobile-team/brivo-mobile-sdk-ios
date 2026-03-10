//
//  UnlockAccessPointViewModel.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import Foundation
import BrivoCore
import BrivoBLE
import BrivoOnAir
import BrivoAccess

class AccessPointDetailsViewModel: ObservableObject {

    // MARK: - Properties

    let selectedAccessPoint: BrivoSelectedAccessPoint?
    @Published var isShowingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLocked = true
    @Published var isShowingToast = false
    @Published var isShowingLoading = false
    @Published var isShowingDormakabaToast = false
    @Published var shouldShowCopyToast: Bool = false
    @Published var shouldShowBottomSheet: Bool = false
    @Published var shouldForceInternetUnlock: Bool = false
    
    var shouldShowInternetUnlockToggle: Bool {
        selectedAccessPoint?.doorType == .wavelynx
    }
    
    private(set) lazy var doorExtendedDetails: [ExtendedInfoItem] = {
        
        guard let selectedAccessPoint = selectedAccessPoint else {
            return []
        }
        let id = String(selectedAccessPoint.accessPointPath.accessPointId)
        let doorType = selectedAccessPoint.doorType.stringValue
        let modelId = selectedAccessPoint.deviceModelId
        let lockID = selectedAccessPoint.controlLockId.map { String($0) }
        let readerUid = selectedAccessPoint.readerUid
        let twoFactor = selectedAccessPoint.isTwoFactorEnabled == true ? "Enabled" : "Disabled"
        let rssi = String(selectedAccessPoint.minimumPanelRssi)
        let timeframe = String(selectedAccessPoint.timeframe)

        return [
            ExtendedInfoItem(name: "Access Point ID", value: id),
            ExtendedInfoItem(name: "Door Type", value: doorType),
            ExtendedInfoItem(name: "Door model ID", value: modelId),
            ExtendedInfoItem(name: "Lock ID", value: lockID),
            ExtendedInfoItem(name: "Reader UID", value: readerUid),
            ExtendedInfoItem(name: "Two Factor Status", value: twoFactor),
            ExtendedInfoItem(name: "Minimum Panel Rssi", value: rssi),
            ExtendedInfoItem(name: "Time Frame", value: timeframe)
        ]
    }()

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
    
    //MARK: - Public

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
            if selectedAccessPoint.doorType == .dormakaba {
                isShowingDormakabaToast = true
            }
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
                                                                           unlockStrategy: shouldForceInternetUnlock ? .forceInternetUnlockforBrivoDoors : nil,
                                                                           cancellationSignal: cancellationSignal) {
                await MainActor.run {
                    if result.accessPointCommunicationState == .success {
                        timer.invalidate()
                        self.setLocked(isLocked: false)
                        self.isShowingDormakabaToast = false
                        isShowingLoading = false
                        self.isShowingToast = true
                    } else if result.accessPointCommunicationState == .failed {
                        timer.invalidate()
                        self.resetToInitialState()

                        if let error = result.error {
                            self.displayErrorMessage(
                                message: (error.localizedDescription) + " " + "Status Code: \(error.code)"
                            )
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
                        self.displayErrorMessage(
                            message: (result.error?.localizedDescription ?? "") + " " + "Status Code: \(result.error?.code ?? 0)"
                        )
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
        isShowingDormakabaToast = false
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

    private func displayErrorMessage(
        title: String = "Error",
        message: String
    ) {
        self.alertTitle = title
        self.alertMessage = message
        self.isShowingAlert = true
    }
}
