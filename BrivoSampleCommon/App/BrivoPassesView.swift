//
//  BrivoPassesView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI
import BrivoCore
import BrivoAccess
import BrivoOnAir
import _PassKit_SwiftUI
#if canImport(BrivoBLEAllegion)
import BrivoBLEAllegion
#endif
#if canImport(BrivoHIDOrigo)
import BrivoHIDOrigo
#endif

// swiftlint:disable line_length

struct BrivoPassesView: View {
    @StateObject var stateModel = BrivoPassesViewModel()

    var body: some View {
        NavigationStack {
            List {
                if stateModel.brivoOnAirPassListItems.isEmpty {
                    Text("You have no Passes. Please add passes by tapping the + button")
                        .accessibilityIdentifier(AccessibilityIds.noPassesTextView)
                } else {
                    ForEach(stateModel.brivoOnAirPassListItems) { passItem in
                        listItem(passItem: passItem)
                    }
                }
            }
            .onAppear {
                stateModel.onAppear()
            }
            .refreshable { await stateModel.refreshPasses() }
            .navigationTitle("BrivoSDK \(BrivoSDK.sdkVersion)")
#if DEBUG_SWITCH_ENV
            .toolbar(content: switchEnvToolbarButton)
#endif
            .toolbar {
                ToolbarItem {
                    Button {
                        stateModel.isShowingBrivoRedeemSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityIdentifier(AccessibilityIds.navigationPlusButton)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        UnlockAccessPointView(stateModel: .init())
                    } label: {
                        Text("Magic Button")
                    }
                }
            }
            .sheet(isPresented: $stateModel.isShowingBrivoRedeemSheet) { addBrivoPassSheet }
            //Commented the code in case we continue with HID Origo wallet integration
            //Will remove if not needed
            //#if canImport(BrivoHIDOrigo)
            //.sheet(isPresented: $stateModel.isShowingOrigoActivationSheet) { addOrigoPassSheet }
            //#endif
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIScene.willEnterForegroundNotification)) { _ in
                Task {
                    await stateModel.refreshPasses()
                }
            }
    }

    // MARK: - Private
#if DEBUG_SWITCH_ENV
    @ToolbarContentBuilder
    func switchEnvToolbarButton() -> some ToolbarContent {
        ToolbarItem {
            Button {
                stateModel.isShowingSwitchEnvironments.toggle()
            } label: {
                Image(systemName: "switch.2")
                    .accessibilityIdentifier(AccessibilityIds.navigationSwitchEnvButton)
            }
            .popover(isPresented: $stateModel.isShowingSwitchEnvironments) {
                SwitchEnvironmentsView(stateModel: stateModel)
            }
            .alert(isPresented: $stateModel.isShowingAlert) {
                Alert(
                    title: Text(stateModel.alertTitle),
                    message: Text(stateModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
#endif

    private func listItem(passItem: BrivoOnAirPassListItem) -> some View {
        Section {
            if let sites = passItem.onAirPass.sites {
                if sites.isEmpty {
                    Text("There are no sites assigned to you")
                }
                ForEach(sites, id: \.self) { site in
                    NavigationLink {
                        AccessPointView(stateModel: .init(brivoOnAirPass: passItem.onAirPass, brivoSites: site))
                    } label: {
                        Text(site.siteName ?? "")
                    }
                }
            }
        } header: {
            VStack(alignment: .leading) {
                Text("\(passItem.onAirPass.accountName ?? "")").accessibilityIdentifier(AccessibilityIds.accountNameTextView)
                Text("Account ID: \(passItem.onAirPass.accountId)")
                Text("\(passItem.onAirPass.firstName ?? "") \(passItem.onAirPass.lastName ?? "")")
                Text("Pass ID: \(passItem.onAirPass.passId ?? "")")
            }
        } footer: {
            #if canImport(BrivoHIDOrigo)
            HStack {
                Text("HID ORIGO: ")
                switch passItem.hidNFCAddToWalletStatus {
                case .alreadyAddedToWallet:
                    Text("Already added to Wallet")
                case .canBeAddedToWallet:
                    AddPassToWalletButton {
                        Task {
                            await stateModel.addToWallet(pass: passItem.onAirPass)
                        }
                    }
                    .addPassToWalletButtonStyle(.blackOutline)
                case .notEligibleForAddingToWallet:
                    Text("Not eligible for adding to Wallet")
                @unknown default:
                    Text("Unknown")
                }
            }
            #endif
        }
    }

    @ViewBuilder
    private var addBrivoPassSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle(isOn: $stateModel.isEURegion) {
                    Text(stateModel.isEURegion ? "EU Region" : "US Region")
                }
                TextField("Pass ID", text: $stateModel.passID, prompt: Text("Pass ID"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(AccessibilityIds.mobilePassEmailField)
                TextField("Pass Code", text: $stateModel.passCode, prompt: Text("Pass Code"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(AccessibilityIds.mobilePassInviteCodeField)
                Spacer()
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            .toolbar {
                Button {
                    Task {
                        await stateModel.redeemPass()
                    }
                } label: {
                    if stateModel.isSubmittingBrivoPass {
                        ProgressView()
                    } else {
                        Text("Add Pass")
                            .accessibilityIdentifier(AccessibilityIds.redeemInviteButton)
                    }
                }
            }
            .disabled(stateModel.isSubmittingBrivoPass)
        }
        .presentationDetents([.fraction(0.30)])
        .alert(isPresented: $stateModel.isShowingAlert) {
            Alert(
                title: Text(stateModel.alertTitle),
                message: Text(stateModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

#if canImport(BrivoHIDOrigo)
    //Commented the code in case we continue with HID Origo wallet integration
    //Will remove if not needed
    @ViewBuilder
    private var addOrigoPassSheet: some View {
        VStack {
            Picker("", selection: $stateModel.origoSelectedPassPickerItem) {
                ForEach(stateModel.origoPassPickerItems) { origoPassItem in
                    Text(origoPassItem.title)
                }
            }
            .pickerStyle(.wheel)
            .onAppear {
                stateModel.origoSelectedPassPickerItem = stateModel.origoPassPickerItems.first
            }
            Toggle("Wallet Integration", isOn: $stateModel.isOrigoWalletIntegrationEnabled)
            TextField("Origo Activation Code",
                      text: $stateModel.origoInvitationCode,
                      prompt: Text("Origo Activation Code"))
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .accessibilityIdentifier(AccessibilityIds.origoActivationCodeField)
            Button("Submit") {
                Task {
                    await stateModel.redeemOrigoInvitationCode()
                }
            }
            .accessibilityIdentifier(AccessibilityIds.origoRedeemButton)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(stateModel.origoInvitationCode.isEmpty)
        }
        .disabled(stateModel.isSubmittingOrigoInvitationCode)
        .padding()
        .overlay(origoLoadingOverlay)
        .presentationDetents([.fraction(0.4)])
        .alert(isPresented: $stateModel.isShowingAlert) {
            Alert(
                title: Text(stateModel.alertTitle),
                message: Text(stateModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var origoLoadingOverlay: some View {
        if stateModel.isSubmittingOrigoInvitationCode {
            ProgressView().tint(.gray)
        }
    }
#endif

}

// MARK: - ViewModel

class BrivoPassesViewModel: ObservableObject {
    private var brivoOnAirPasses: [BrivoOnairPass] = []
    @Published var brivoOnAirPassListItems: [BrivoOnAirPassListItem] = []
    @Published var isShowingBrivoRedeemSheet = false
    @Published var isSubmittingBrivoPass = false
    @Published var isShowingOrigoActivationSheet = false
    @Published var isShowingAlert = false
    @Published var isSubmittingOrigoInvitationCode = false
    @Published var isShowingSwitchEnvironments = false
    @Published var selectedEnvironment: Environment?
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
                clientId: Configuration.default.environment.clientId,
                clientSecret: Configuration.default.environment.clientSecret,
                useSDKStorage: true,
                region: self.isEURegion ? Region.eu : Region.us,
                authUrl: Configuration.default.environment.brivoOnAirAuth,
                apiUrl: Configuration.default.environment.brivoOnAirAPI
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
        _ = await brivoSDKBLEAllegion.refreshCredentials(brivoOnAirPass: brivoOnairPass)
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
            showAlert(title: "Error",
                      message: error.localizedDescription)
            return
        }
        showAlert(title: "Error",
                  message: brivoError.errorDescription + " " + "Status Code: \(brivoError.statusCode)")
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

// MARK: - Preview

#Preview {
    BrivoPassesView()
}
// swiftlint:enable line_length
