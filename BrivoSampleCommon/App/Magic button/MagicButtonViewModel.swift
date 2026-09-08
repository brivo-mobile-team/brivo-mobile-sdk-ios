//
//  MagicButtonViewModel.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 29.09.2025.
//

import Foundation
import BrivoCore
import BrivoOnAir
import BrivoAccess
import SwiftUI

@MainActor
class MagicButtonViewModel: ObservableObject {

    // MARK: - Properties

    @MainActor
    let scannerService = BrivoSDKAccess.instance().continuousScannerService
    private var scanTask: Task<Void, Never>?
    
    var brivoOnAirPasses: [BrivoOnairPass]

    @Published var isShowingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isShowingLoading = false
    @Published var magicButtonText: String = ""
    @Published var displayedDevices: [NearbyDevice] = []
    @Published var currentStatus: String = "Idle"

    private var activeUnlockTask: Task<Void, Never>?

    var nearestDevice: NearbyDevice? {
        return displayedDevices.first
    }

    var isMagicButtonDisabled: Bool {
        return displayedDevices.isEmpty || isShowingLoading
    }

    var magicButtonImage: Image {
        switch nearestDevice?.type {
        case .wavelynx:
            Image(.brivoIcon)
        case .allegion, .allegionBle:
            Image(.allegionIcon)
        case .hidOrigo:
            Image(.hidIcon)
        case .dormakaba, .yonomi, .realSyncBle, .salto, nil, .internet:
            Image("")
        default:
            Image("")
        }
    }

    // MARK: - init

    init(brivoOnAirPasses: [BrivoOnairPass],
        isShowingAlert: Bool = false,
         alertTitle: String = "",
         alertMessage: String = "") {
        self.brivoOnAirPasses = brivoOnAirPasses
        self.isShowingAlert = isShowingAlert
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
    }

    //MARK: - Public

    func openAccessPoint(for selectedDevice: NearbyDevice?) {
        guard let selectedDevice = selectedDevice else {
            displayErrorMessage(message: "Device information is missing.")
            return
        }

        guard !isShowingLoading else { return }

        self.magicButtonText = "Unlocking \(selectedDevice.name)"
        isShowingLoading = true

        activeUnlockTask?.cancel()

        activeUnlockTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await withTimeout(after: .seconds(15)) {
                    try await self.performUnlock(for: selectedDevice)
                }
            } catch is TimeoutError {
                self.isShowingLoading = false
                self.displayErrorMessage(message: "unlock timed out")
                self.magicButtonText = "\(selectedDevice.name)"
            } catch is CancellationError {
                self.magicButtonText = "\(selectedDevice.name)"
            } catch {
                self.isShowingLoading = false
                self.displayErrorMessage(message: error.localizedDescription)
                self.magicButtonText = "\(selectedDevice.name)"
            }
        }
    }

    private func performUnlock(for device: NearbyDevice) async throws {
        let stream = BrivoSDKAccess.instance().unlockDiscoveredAccessPoint(device: device)

        for try await result in stream {
            switch result.accessPointCommunicationState {
            case .success:
                isShowingLoading = false
                magicButtonText = "\(device.name) unlocked."

            case .failed:
                isShowingLoading = false
                magicButtonText = "Failed to unlock \(device.name)."
                if let error = result.error {
                    displayErrorMessage(message: "\(error.localizedDescription) Status Code: \(error.code)")
                }

            default:
                break
            }
        }

        if isShowingLoading {
            isShowingLoading = false
            magicButtonText = "\(device.name)"
        }
    }

    @MainActor
    func startScan() {
        scanTask?.cancel()

        scanTask = Task {
            do {
                let eventStream = try await BrivoSDKAccess.instance().startScanForNearbyDevicesWithSDKStorage()

                for await event in eventStream {
                    switch event {
                    case .stateChanged(let state):
                        self.currentStatus = String(describing: state)

                    case .devicesUpdated(let devices):
                        if !isShowingLoading {
                            self.displayedDevices = devices.sorted {
                                $0.rssi > $1.rssi
                            }
                            self.magicButtonText = "\(nearestDevice?.name ?? "")"
                        }

                    case .error(let scannerError):
                        switch scannerError {
                        case .scanAlreadyInProgress:
                            self.currentStatus = "A scan is already in progress"
                        case .providerFailed(let provider, let underlyingError):
                            self.currentStatus = "The \(provider) scanner failed: \(underlyingError.localizedDescription)"
                            self.displayErrorMessage(message: currentStatus)
                        default:
                            self.currentStatus = "Unknown scanner error"
                            self.displayErrorMessage(message: currentStatus)
                        }
                    }
                }
            } catch {
                displayErrorMessage(message: "Failed to start scanning: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func stopScan() {
        BrivoSDKAccess.instance().stopScanForNearbyDevices()
        scanTask?.cancel()
    }

    // MARK: - Private

    private func unlockSelectedDiscoveredDevice(
        device: NearbyDevice,
        cancellationSignal: CancellationSignal,
        timer: Timer
    ) {
        Task {
            let stream = BrivoSDKAccess.instance().unlockDiscoveredAccessPoint(device: device)
            do {
                for try await result in stream {
                    await MainActor.run {
                        if result.accessPointCommunicationState == .success {
                            timer.invalidate()
                            self.isShowingLoading = false
                            self.magicButtonText = "\(device.name) unlocked."
                        } else if result.accessPointCommunicationState == .failed {
                            self.isShowingLoading = false
                            self.magicButtonText = "Failed to unlock \(device.name)."
                            timer.invalidate()
                            if let error = result.error {
                                self.displayErrorMessage(message: (error.localizedDescription) + " " + "Status Code: \(error.code)")
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    timer.invalidate()
                    self.isShowingLoading = false
                    self.displayErrorMessage(message: error.localizedDescription)
                }
            }
            magicButtonText = "\(device.name)"
        }
    }

    private func unlockSelectedAccessPoint(
        passId: String,
        accessPointIdString: String,
        cancellationSignal: CancellationSignal,
        timer: Timer
    ) {
        Task {
            let brivoSDKAccess = BrivoSDKAccess.instance()
            let stream = await brivoSDKAccess.unlockAccessPoint(
                passId: passId,
                accessPointId: accessPointIdString,
                cancellationSignal: cancellationSignal
            )

            for try await result in stream {
                await MainActor.run {
                    if result.accessPointCommunicationState == .success {
                        timer.invalidate()

                    } else if result.accessPointCommunicationState == .failed {
                        timer.invalidate()
                        isShowingLoading = false
                        if let error = result.error {
                            self.displayErrorMessage(message: (error.localizedDescription) + " " + "Status Code: \(error.code)")
                        }
                    }
                }
            }
        }
    }

    private func displayErrorMessage(
        title: String = "Error",
        message: String
    ) {
        self.alertTitle = title
        self.alertMessage = message
        self.isShowingAlert = true
    }

    func cancelUnlock() {
        activeUnlockTask?.cancel()
        isShowingLoading = false
    }
}
