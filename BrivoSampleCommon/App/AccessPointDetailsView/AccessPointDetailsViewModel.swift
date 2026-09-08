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

enum UnlockProgress {
    case idle
    case requested
    case sdk(AccessPointCommunicationState)
    case cancelled(from: AccessPointCommunicationState?)
    case streamFailed(Error)

    var communicationState: AccessPointCommunicationState? {
        if case .sdk(let state) = self { return state }
        return nil
    }
}

extension UnlockProgress: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle: "Idle"
        case .requested: "Unlock requested"
        case .sdk(let state): state.description
        case .cancelled(let state): state.map { "Cancelled from \($0)" } ?? "Cancelled"
        case .streamFailed(let error): "Stream threw: \(error.localizedDescription)"
        }
    }
}

class AccessPointDetailsViewModel: ObservableObject {

    // MARK: - Properties

    let selectedAccessPoint: BrivoSelectedAccessPoint
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
    @Published private(set) var unlockState: UnlockProgress = .idle
    @Published private(set) var canCancelUnlock: Bool = false

    private var activeCancellationSignal: CancellationSignal?
    private var activeUnlockTask: Task<Void, Never>?
    private var activeUnlockTimer: Timer?

    var shouldShowInternetUnlockToggle: Bool {
        selectedAccessPoint.doorType == .wavelynx
    }

    private(set) lazy var doorExtendedDetails: [ExtendedInfoItem] = {

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

    init(selectedAccessPoint: BrivoSelectedAccessPoint,
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

    @MainActor
    func openAccessPoint() {
        guard activeCancellationSignal == nil else { return }

        isShowingLoading = true
        setUnlockedTimer()

        unlockState = .requested

        let cancellationSignal = CancellationSignal()
        let timer = Timer(timeInterval: 30.0, repeats: false) {[weak self] (timer) in
            cancellationSignal.isCancelled = true
            self?.unlockState = .cancelled(from: self?.unlockState.communicationState)
            self?.resetToInitialState()
            timer.invalidate()
            self?.clearActiveUnlock()
        }

        activeCancellationSignal = cancellationSignal
        canCancelUnlock = true
        activeUnlockTimer = timer

        let passId = selectedAccessPoint.accessPointPath.passId
        let accessPointIdString = "\(selectedAccessPoint.accessPointPath.accessPointId)"
        if selectedAccessPoint.doorType == .dormakaba {
            isShowingDormakabaToast = true
        }
        unlockSelectedAccessPoint(passId: passId,
                                  accessPointIdString: accessPointIdString,
                                  cancellationSignal: cancellationSignal,
                                  timer: timer)
        RunLoop.current.add(timer, forMode: .common)
    }

    @MainActor
    func cancelUnlock() {
        activeCancellationSignal?.isCancelled = true
        activeUnlockTask?.cancel()
        unlockState = .cancelled(from: unlockState.communicationState)
        resetToInitialState()
        clearActiveUnlock()
    }

    // MARK: - Private

    @MainActor
    private func unlockSelectedAccessPoint(
        passId: String,
        accessPointIdString: String,
        cancellationSignal: CancellationSignal,
        timer: Timer
    ) {
        activeUnlockTask = Task {
            let brivoSDKAccess = BrivoSDKAccess.instance()
            do {
                for try await result in await brivoSDKAccess.unlockAccessPoint(
                    passId: passId,
                    accessPointId: accessPointIdString,
                    unlockStrategy: shouldForceInternetUnlock ? .forceInternetUnlockforBrivoDoors : nil,
                    cancellationSignal: cancellationSignal
                ) {
                    await MainActor.run {
                        self.unlockState = .sdk(result.accessPointCommunicationState)

                        if result.accessPointCommunicationState == .success {
                            timer.invalidate()
                            self.clearActiveUnlock()
                            self.setLocked(isLocked: false)
                            self.isShowingDormakabaToast = false
                            self.isShowingLoading = false
                            self.isShowingToast = true
                        } else if result.accessPointCommunicationState == .failed {
                            timer.invalidate()
                            self.clearActiveUnlock()
                            self.resetToInitialState()

                            if let error = result.error {
                                self.displayErrorMessage(
                                    message: (error.localizedDescription) + " " + "Status Code: \(error.code)"
                                )
                            }
                        }
                    }
                }
            } catch is CancellationError {
                // cancelUnlock() already set .cancelled and reset the UI; don't overwrite it.
            } catch {
                await MainActor.run {
                    self.unlockState = .streamFailed(error)
                    timer.invalidate()
                    self.clearActiveUnlock()
                    self.resetToInitialState()
                }
            }
        }
    }

    private func clearActiveUnlock() {
        canCancelUnlock = false
        activeUnlockTask = nil
        activeUnlockTimer?.invalidate()
        activeUnlockTimer = nil
        activeCancellationSignal = nil
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
