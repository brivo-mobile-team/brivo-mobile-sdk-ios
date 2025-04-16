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


// MARK: - ViewModel

class BrivoPassesViewModel: ObservableObject {
    private var brivoOnAirPasses: [BrivoOnairPass] = []
    @Published var brivoOnAirPassListItems: [BrivoOnAirPassListItem] = []
    @Published var isShowingBrivoRedeemSheet = false
    @Published var isSubmittingBrivoPass = false
    @Published var isShowingOrigoActivationSheet = false
    @Published var isShowingAlert = false
    @Published var isSubmittingOrigoInvitationCode = false
    @Published var brivoConfig: BrivoSDKConfiguration?
    @Published var isEURegion = false {
        didSet {
            resetPasses()
            setRegion(isEURegion: isEURegion)
            setupBrivoConfiguration()
        }
    }
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    @Published var passID = ""
    @Published var passCode = ""
    @Published var origoInvitationCode = ""
    @Published var origoSelectedPassPickerItem: BrivoOnAirPassPickerItem?
    @Published var isOrigoWalletIntegrationEnabled: Bool = false
    var origoPassPickerItems: [BrivoOnAirPassPickerItem] = []
    var brivoSDKVersion: String {
        "BrivoSDK \(BrivoSDK.sdkVersion)"
    }
    
    func onAppear() {
        setRegion(isEURegion: isEURegion)
        setupBrivoConfiguration()
        Task { await refreshPasses() }
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
    
#if canImport(BrivoHIDOrigo)
    @MainActor
    func redeemOrigoInvitationCode() async {
        guard let selectedOnAirPass = origoSelectedPassPickerItem?.onAirPass else {
            return
        }
        guard let redeemTarget = getHidOrigoRedeemTarget() else {
            return
        }
        isSubmittingOrigoInvitationCode = true
        switch await BrivoSDKHIDOrigo.instance.refreshCredentials(target: redeemTarget) {
        case .success:
            isSubmittingOrigoInvitationCode = false
            isShowingOrigoActivationSheet = false
            origoInvitationCode = ""
            updateUI()
        case .failure(let brivoError):
            isSubmittingOrigoInvitationCode = false
            onError(brivoError)
        }
    }
#endif
    
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
            for brivoOnAirPass in brivoOnAirPasses {
#if canImport(BrivoBLEAllegion)
                await refreshAllegionCredentialsIfPossible(brivoOnAirPass)
#endif
#if canImport(BrivoHIDOrigo)
                await getHidOrigoActivationCodeIfPossible(brivoOnAirPass)
#endif
            }
            updateUI()
        } catch {
            onError(error)
        }
    }
    
#if canImport(BrivoHIDOrigo)
    @MainActor
    func addToWallet(pass: BrivoOnairPass) async {
        switch await BrivoSDKHIDOrigo.instance.addNFCCredentialToWallet(pass: pass) {
        case .success(let pkPasses):
            showAlert(title: "Success",
                      message: pkPasses.map { $0.description }.joined(separator: ","))
        case .failure(let error):
            onError(error)
        }
    }
#endif
    
    // MARK: - Private
    private var previousUpdateTask: Task<Void, Never>?
    
    private func updateUI() {
        previousUpdateTask = Task { @MainActor [previousUpdateTask] in
            await previousUpdateTask?.value
            var newBrivoOnAirPassListItems = [BrivoOnAirPassListItem]()
            for brivoOnAirPass in brivoOnAirPasses {
                var addToWalletStatusResult: NFCAddToWalletStatus? = .notEligibleForAddingToWallet
#if canImport(BrivoHIDOrigo)
                addToWalletStatusResult = try? await BrivoSDKHIDOrigo.instance.getNFCCredentialStatus(pass: brivoOnAirPass).get()
#endif
                newBrivoOnAirPassListItems.append(.init(onAirPass: brivoOnAirPass, hidNFCAddToWalletStatus: addToWalletStatusResult ?? .notEligibleForAddingToWallet))
            }
            self.brivoOnAirPassListItems = newBrivoOnAirPassListItems
            self.origoPassPickerItems = brivoOnAirPassListItems
                .filter {
                    switch $0.hidNFCAddToWalletStatus {
                    case .notEligibleForAddingToWallet:
                        return true
                    case .alreadyAddedToWallet, .canBeAddedToWallet:
                        return false
                    @unknown default:
                        return false
                    }
                }
                .map { $0.onAirPass }
                .filter { brivoOnAirPass in
                    guard brivoOnAirPass.hasHidOrigoMobilePass, let sites = brivoOnAirPass.sites else { return false }
                    return  sites.contains { site in
                        site.accessPoints?.contains { $0.readerType == .hidOrigo} ?? false
                    }
                }
                .map { BrivoOnAirPassPickerItem(onAirPass: $0) }
#if canImport(BrivoHIDOrigo)
            self.showOrigoActivationSheetIfNeeded()
#endif
        }
    }
    
#if canImport(BrivoHIDOrigo)
    private func getHidOrigoRedeemTarget () -> RedeemTarget? {
        guard let selectedOnAirPass = origoSelectedPassPickerItem?.onAirPass else {
            return nil
        }
        return isOrigoWalletIntegrationEnabled ? .wallet(invitationCode: origoInvitationCode, pass: selectedOnAirPass) : .ble(pass: selectedOnAirPass)
    }
#endif
    
    private func setRegion(isEURegion: Bool) {
        UserDefaultsAccessService().setRegion((isEURegion ? Region.eu : Region.us).rawValue)
    }
    
    private func setupBrivoConfiguration() {
        do {
            let brivoConfiguration = try BrivoSDKConfiguration(
                clientId: Configuration.default.clientId,
                clientSecret: Configuration.default.clientSecret,
                useSDKStorage: true,
                region: self.isEURegion ? Region.eu : Region.us,
                authUrl: Configuration.default.brivoOnAirAuth,
                apiUrl: Configuration.default.brivoOnAirAPI
            )
            BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)
        } catch let error {
            onError(error)
        }
    }
    
#if canImport(BrivoHIDOrigo)
    private func showOrigoActivationSheetIfNeeded() {
        Task { @MainActor in
            if let redeemTarget = getHidOrigoRedeemTarget() {
                switch redeemTarget {
                case .wallet:
                    isShowingOrigoActivationSheet = !origoPassPickerItems.isEmpty && !BrivoSDKHIDOrigo.instance.isEndpointSetup
                case .ble:
                    isShowingOrigoActivationSheet = false
                @unknown default:
                    isShowingOrigoActivationSheet = false
                }
            }
        }
    }
#endif
    
#if canImport(BrivoBLEAllegion)
    private func refreshAllegionCredentialsIfPossible(_ brivoOnairPass: BrivoOnairPass) async {
        guard brivoOnairPass.hasAllegionBleCredentials else { return }
        let brivoSDKBLEAllegion = BrivoSDKBLEAllegion.instance
        _ = await brivoSDKBLEAllegion.refreshCredentials(
            brivoOnAirPass: brivoOnairPass,
            refreshType: .ignoringLocalCacheData
        )
    }
#endif
    
#if canImport(BrivoHIDOrigo)
    private func getHidOrigoActivationCodeIfPossible(_ brivoOnairPass: BrivoOnairPass) async {
        switch await BrivoSDKHIDOrigo.instance.refreshCredentials(target: .ble(pass: brivoOnairPass)) {
        case .success:
            showAlert(title: "Success", message: "HID Origo activated successfully")
        case .failure(let error):
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
    let hidNFCAddToWalletStatus: NFCAddToWalletStatus
}

// MARK: - BrivoOnAirPassPickerItem

struct BrivoOnAirPassPickerItem: Identifiable, Hashable {
    var id: String { onAirPass.passId ?? UUID().uuidString }
    var title: String { "\(onAirPass.accountName ?? "") - \(onAirPass.firstName ?? "") \(onAirPass.lastName ?? "")" }
    let onAirPass: BrivoOnairPass
}
