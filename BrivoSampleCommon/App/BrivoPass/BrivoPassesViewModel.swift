//
//  BrivoPassesViewModel.swift
//  BrivoSampleApp
//
//  Created by Catalin Demian on 13.03.2025.
//

import Foundation
import BrivoCore
import BrivoOnAir
import BrivoAccess

class BrivoPassesViewModel: ObservableObject {
    // MARK: - Properties

    private var brivoOnAirPasses: [BrivoOnairPass] = []
    private var brivoSDKAccess = BrivoSDKAccess.instance()

    @Published var brivoOnAirPassListItems: [BrivoOnAirPassListItem] = []
    @Published var isShowingBrivoRedeemSheet = false
    @Published var isSubmittingBrivoPass = false
    @Published var isShowingAlert = false
    @Published var brivoConfig: BrivoSDKConfiguration?
    @Published var isEURegion = false {
        didSet {
            handleRegionChange(isEURegion: isEURegion)
        }
    }
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    @Published var passID = ""
    @Published var passCode = ""
    @Published var shouldShowDetailsBottomSheet: Bool = false
    
    @Published var passExtendedDetails: [ExtendedInfoItem] = []

    init() {
        cacheRegion(isEURegion: isEURegion)
        do {
            try setupBrivoConfiguration()
        } catch {
            onError(error)
        }
    }
    
    var brivoSDKVersion: String {
        "BrivoSDK \(BrivoSDK.sdkVersion)"
    }

    var shouldShowEmptyView: Bool {
        brivoOnAirPassListItems.isEmpty
    }
    
    @MainActor
    func redeemPass() async {
        do {
            isSubmittingBrivoPass = true
            _ = try await BrivoSDKOnAir.instance().redeemPass(passId: passID, passCode: passCode).get()
            passID = ""
            passCode = ""
            isSubmittingBrivoPass = false
            isShowingBrivoRedeemSheet = false
            await refreshPasses()
        } catch {
            isSubmittingBrivoPass = false
            onError(error)
        }
    }
    
    func resetPasses() {
        BrivoUserDefaults.setDictionary(value: [:], forKey: BrivoCore.Constants.KEY_PASSES)
        BrivoUserDefaults.setDictionary(value: [:], forKey: BrivoCore.Constants.KEY_PASSES_EU)
        brivoOnAirPasses = []
        updateUI()
    }
    
    func getPassUIModel(passItem: BrivoOnAirPassListItem) {
      passExtendedDetails = [
        ExtendedInfoItem(name: "Pass Transfer Status", value: passItem.onAirPass.enablePassTransfer ? "Enabled" : "Disabled"),
        ExtendedInfoItem(name: "Brivo Wallet Pass Status", value:passItem.onAirPass.nfcEnabled ? "Enabled" : "Disabled"),
        ExtendedInfoItem(name: "Allegion BLE Credentials Status", value: passItem.onAirPass.hasAllegionBleCredentials ? "Enabled" : "Disabled"),
        ExtendedInfoItem(name: "HID Origo Mobile Pass", value: passItem.onAirPass.hasHidOrigoMobilePass ? "Enabled" : "Disabled"),
        ExtendedInfoItem(name: "HID Origo Wallet Pass Status", value: passItem.onAirPass.hidOrigoWalletPassEnabled ? "Enabled" : "Disabled"),
        ExtendedInfoItem(name: "Dormakaba Mobile Pass",
                         value: passItem.onAirPass.dormakabaMobilePassEnabled ? "Enabled" : "Disabled")
        ]
    }

    @MainActor
    func refreshPasses() async {
        do {
            let storedPasses = try await BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses().get()
            var newPasses = [BrivoOnairPass]()
            for brivoOnAirPass in storedPasses {
                guard let tokens = brivoOnAirPass.brivoOnairPassCredentials?.tokens else { return }
                let refreshedPass = try await BrivoSDKOnAir.instance().refreshPass(brivoTokens: tokens).get()
                if let refreshedPass = refreshedPass {
                    newPasses.append(refreshedPass)
                }
            }
            brivoOnAirPasses = newPasses.sorted(by: { $0.accountName ?? "N/A" < $1.accountName ?? "N/A" })
            _ = await brivoSDKAccess.refreshCredentials(passes: brivoOnAirPasses)
            updateUI()
        } catch {
            onError(error)
        }
    }
    
    func handleRegionChange(isEURegion: Bool) {
        resetPasses()
        cacheRegion(isEURegion: isEURegion)
        do {
            try setupBrivoConfiguration()
        } catch {
            onError(error)
        }
    }

    // MARK: - Private
    private var previousUpdateTask: Task<Void, Never>?
    
    private func updateUI() {
        previousUpdateTask?.cancel()
        previousUpdateTask = Task { @MainActor  in
            var newBrivoOnAirPassListItems = [BrivoOnAirPassListItem]()
            for brivoOnAirPass in brivoOnAirPasses {
                guard !Task.isCancelled else { return }
                newBrivoOnAirPassListItems.append(.init(onAirPass: brivoOnAirPass))
            }
            guard !Task.isCancelled else { return }
            self.brivoOnAirPassListItems = newBrivoOnAirPassListItems
        }
    }
    
    private func cacheRegion(isEURegion: Bool) {
        UserDefaultsAccessService().setRegion((isEURegion ? Region.eu : Region.us).rawValue)
    }
    
    private func setupBrivoConfiguration() throws {
        let brivoConfiguration = try BrivoSDKConfiguration.Builder(
            clientId: Configuration.default.clientId,
            clientSecret: Configuration.default.clientSecret,
            useSDKStorage: true
        )
            .region(self.isEURegion ? .eu : .us)
            .authUrl(Configuration.default.brivoOnAirAuth)
            .apiUrl(Configuration.default.brivoOnAirAPI)
            .brivoBLEAllegionConfiguration()
            .brivoDormakabaConfiguration(
                .init(
                    mobileAppID: Configuration.default.dormakabaMobileAppID,
                    userName: Configuration.default.dormakabaUserName,
                    password: Configuration.default.dormakabaPassword,
                    serverURL: Configuration.default.dormakabaServerURL,
                    evoloSmartProjectId: Configuration.default.dormakabaEvoloSmartProjectID,
                    unlockTimeoutDuration: Configuration.default.dormakabaUnlockTimeoutDuration
                )
            )
            .brivoSDKHIDOrigoConfiguration()
            .brivoSaltoConfiguration()
            .build()
        BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alertTitle = title
            self.alertMessage = message
            self.isShowingAlert = true
        }
    }
    
    private func onError(_ error: Error) {
        guard let brivoError = error as? BrivoError else {
            showAlert(
                title: "Error",
                message: error.localizedDescription
            )
            return
        }
        showAlert(
            title: "Error",
            message: brivoError.localizedDescription + " " + "Status Code: \(brivoError.code)"
        )
    }
}

// MARK: - BrivoOnAirPassListItem

struct BrivoOnAirPassListItem: Identifiable, Hashable {
    var id: String { onAirPass.passId ?? UUID().uuidString }
    var title: String { "\(onAirPass.accountName ?? "") - \(onAirPass.firstName ?? "") \(onAirPass.lastName ?? "")" }
    let onAirPass: BrivoOnairPass
}
