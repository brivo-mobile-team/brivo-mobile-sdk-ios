//
//  BrivoPassesViewModel.swift
//  BrivoSampleApp
//
//  Created by Catalin Demian on 13.03.2025.
//

import Foundation
import BrivoCore
import BrivoOnAir
#if canImport(BrivoBLEAllegion)
import BrivoBLEAllegion
#endif
#if canImport(BrivoHIDOrigo)
import BrivoHIDOrigo
#endif
#if canImport(BrivoDormakaba)
import BrivoDormakaba
#endif

class BrivoPassesViewModel: ObservableObject {
    // MARK: - Properties

    private var brivoOnAirPasses: [BrivoOnairPass] = []
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
    var brivoSDKVersion: String {
        "BrivoSDK \(BrivoSDK.sdkVersion)"
    }

    var shouldShowEmptyView: Bool {
        brivoOnAirPassListItems.isEmpty
    }

    init() {
        cacheRegion(isEURegion: isEURegion)
        do {
            try setupBrivoConfiguration()
            setupDormakaba()
        } catch {
            onError(error)
        }
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
    
    @MainActor
    func refreshPasses() async {
        do {
            if brivoOnAirPasses.isEmpty {
                let passes = try await BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses().get()
                self.brivoOnAirPasses = passes
            } else {
                var newPasses = [BrivoOnairPass]()
                for brivoOnAirPass in brivoOnAirPasses {
                    guard let tokens = brivoOnAirPass.brivoOnairPassCredentials?.tokens else { return }
                    let refreshedPass = try await BrivoSDKOnAir.instance().refreshPass(brivoTokens: tokens).get()
                    if let refreshedPass = refreshedPass {
                        newPasses.append(refreshedPass)
                    }
                }
                self.brivoOnAirPasses = newPasses
            }
#if canImport(BrivoBLEAllegion)
            await refreshAllegionCredentialsIfPossible(brivoOnAirPasses)
#endif
#if canImport(BrivoHIDOrigo)
            for brivoOnAirPass in brivoOnAirPasses {
                await refreshHidOrigoCredentialsIfPossible(brivoOnAirPass)
            }
#endif
#if canImport(BrivoDormakaba)
            await refreshDormakabaCredentialsIfPossible(brivoOnAirPasses)
#endif
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
    
#if canImport(BrivoHIDOrigo)
    @MainActor
    func addToWallet(pass: BrivoOnairPass) async {
        switch await BrivoSDKHIDOrigo.instance.addNFCCredentialToWallet(pass: pass) {
        case .success(let pkPasses):
            let message = pkPasses.map { $0.localizedDescription }.joined(separator: "\n")
            showAlert(title: "Success", message: message)
        case .failure(let error):
            onError(error)
        }
    }
#endif
    
    // MARK: - Private
    private var previousUpdateTask: Task<Void, Never>?
    
    private func updateUI() {
        previousUpdateTask?.cancel()
        previousUpdateTask = Task { @MainActor  in
            var newBrivoOnAirPassListItems = [BrivoOnAirPassListItem]()
            for brivoOnAirPass in brivoOnAirPasses {
                guard !Task.isCancelled else { return }
                var addToWalletStatusResult: AddToWalletStatus = .ineligible(reason: "Not Eligible")
#if canImport(BrivoHIDOrigo)
                switch await BrivoSDKHIDOrigo.instance.getNFCCredentialStatus(pass: brivoOnAirPass) {
                case .success(let status):
                    switch status{
                    case .eligible(let devices):
                        addToWalletStatusResult = .eligible
                    case .notEligible:
                        addToWalletStatusResult = .ineligible(reason: "Not Eligible")
                    @unknown default:
                        addToWalletStatusResult = .ineligible(reason: "Not Eligible. Unknown Status")
                    }
                case .failure:
                    addToWalletStatusResult = .ineligible(reason: "Unsupported")
                }
#endif
                newBrivoOnAirPassListItems.append(.init(onAirPass: brivoOnAirPass, hidNFCAddToWalletStatus: addToWalletStatusResult))
            }
            guard !Task.isCancelled else { return }
            self.brivoOnAirPassListItems = newBrivoOnAirPassListItems
        }
    }
    
    private func cacheRegion(isEURegion: Bool) {
        UserDefaultsAccessService().setRegion((isEURegion ? Region.eu : Region.us).rawValue)
    }
    
    private func setupBrivoConfiguration() throws {
        let brivoConfiguration = try BrivoSDKConfiguration(
            clientId: Configuration.default.clientId,
            clientSecret: Configuration.default.clientSecret,
            useSDKStorage: true,
            region: self.isEURegion ? Region.eu : Region.us,
            authUrl: Configuration.default.brivoOnAirAuth,
            apiUrl: Configuration.default.brivoOnAirAPI
        )
        BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
    }
    
    private func setupDormakaba() {
#if canImport(BrivoDormakaba)
        let brivoDormakabaConfiguration = BrivoDormakabaConfiguration(
            mobileAppID: Configuration.default.dormakabaMobileAppID,
            userName: Configuration.default.dormakabaUserName,
            password: Configuration.default.dormakabaPassword,
            serverURL: Configuration.default.dormakabaServerURL,
            evoloSmartProjectId: Configuration.default.dormakabaEvoloSmartProjectID,
            unlockTimeoutDuration: Configuration.default.dormakabaUnlockTimeoutDuration
        )
        BrivoSDKDormakaba.initialize(configuration: brivoDormakabaConfiguration)
#endif
    }
    
#if canImport(BrivoBLEAllegion)
    private func refreshAllegionCredentialsIfPossible(_ brivoOnairPasses: [BrivoOnairPass]) async {
        let brivoSDKBLEAllegion = BrivoSDKBLEAllegion.instance
		_ = await brivoSDKBLEAllegion.refreshCredentials(brivoOnAirPasses: brivoOnairPasses, refreshType: .validatingCacheData, forceNewCredentials: false)
    }
#endif
    
#if canImport(BrivoHIDOrigo)
    private func refreshHidOrigoCredentialsIfPossible(_ brivoOnairPass: BrivoOnairPass) async {
        switch await BrivoSDKHIDOrigo.instance.refreshCredentials(pass: brivoOnairPass) {
        case .success:
            showAlert(title: "Success", message: "HID Origo activated successfully")
        case .failure(let error):
            guard error.code != BrivoHIDOrigoError.Code.missingRights else { return }
            onError(error)
        }
    }
#endif

#if canImport(BrivoDormakaba)
    private func refreshDormakabaCredentialsIfPossible(_ brivoOnairPasses: [BrivoOnairPass]) async {
        switch await BrivoSDKDormakaba.instance.refreshCredentials(passes: brivoOnairPasses) {
        case .success:
            showAlert(title: "Success", message: "Dormakaba activated successfully")
        case .failure(let error):
            guard error.code != BrivoDormakabaError.Code.missingRights.rawValue else { return }
            onError(error)
        }
    }
#endif

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
    let hidNFCAddToWalletStatus: AddToWalletStatus
}

enum AddToWalletStatus: Equatable, Hashable {
    case eligible
    case ineligible(reason: String)
}
