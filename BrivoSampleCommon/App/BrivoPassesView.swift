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
import BrivoNetworkCore
#if canImport(BrivoBLEAllegion)
import BrivoBLEAllegion
#endif
#if canImport(BrivoHIDOrigo)
import BrivoHIDOrigo
#endif

// swiftlint:disable line_length

struct BrivoPassesView: View {
    @StateObject var stateModel = BrivoPassesViewModel()
    @State private var textFieldContent: String = ""

    var body: some View {
        NavigationStack {
            List {
                if stateModel.brivoOnAirPasses.isEmpty {
                    Text("You have no Passes. Please add passes by tapping the + button")
                        .accessibilityIdentifier(AccessibilityIds.noPassesTextView)
                } else {
                    ForEach(stateModel.brivoOnAirPasses, id: \.self) { pass in
                        Section {
                            if let sites = pass.sites {
                                if sites.isEmpty {
                                    Text("There are no sites assigned to you")
                                }
                                ForEach(sites, id: \.self) { site in
                                    NavigationLink {
                                        AccessPointView(stateModel: .init(brivoOnAirPass: pass, brivoSites: site))
                                    } label: {
                                        Text(site.siteName ?? "")
                                    }
                                }
                            }
                        } header: {
                            VStack(alignment: .leading) {
                                Text("\(pass.accountName ?? "")").accessibilityIdentifier(AccessibilityIds.accountNameTextView)
                                Text("Account ID: \(pass.accountId)")
                                Text("\(pass.firstName ?? "") \(pass.lastName ?? "")")
                                Text("Pass ID: \(pass.passId ?? "")")
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await stateModel.onAppear()
                }
            }
            .refreshable {
                Task {
                    await stateModel.refreshPasses()
                }
            }
            .navigationTitle("BrivoSDK \(BrivoSDK.sdkVersion)")
#if DEBUG_SWITCH_ENV
            .toolbar(content: switchEnvToolbarButton)
#endif
            .toolbar {
                ToolbarItem {
                    Button {
                        stateModel.isShowingAddSheet.toggle()
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
            .sheet(isPresented: $stateModel.isShowingAddSheet) { addBrivoPassSheet }
#if canImport(BrivoHIDOrigo)
            .sheet(isPresented: $stateModel.isShowingOrigoActivationSheet) { addOrigoPassSheet }
#endif
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
                    stateModel.redeemPass()
                } label: {
                    Text("Add Pass")
                        .accessibilityIdentifier(AccessibilityIds.redeemInviteButton)
                }
            }
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
    @ViewBuilder
    private var addOrigoPassSheet: some View {
        VStack {
            TextField("Origo Activation Code", text: $stateModel.origoInvitationCode, prompt: Text("Origo Activation Code"))
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .accessibilityIdentifier(AccessibilityIds.origoActivationCodeField)
            Button("Submit") {
                stateModel.redeemOrigoInvitationCode()
            }
            .accessibilityIdentifier(AccessibilityIds.origoRedeemButton)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .disabled(stateModel.isSubmittingOrigoInvitationCode)
        .padding()
        .overlay(loadingOverlay)
        .presentationDetents([.fraction(0.2)])
        .alert(isPresented: $stateModel.isShowingAlert) {
            Alert(
                title: Text(stateModel.alertTitle),
                message: Text(stateModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
#endif

    @ViewBuilder
    private var loadingOverlay: some View {
        if stateModel.isSubmittingOrigoInvitationCode {
            ProgressView().tint(.gray)
        }
    }
}

// MARK: - ViewModel
class BrivoPassesViewModel: ObservableObject {
    @Published var brivoOnAirPasses: [BrivoOnairPass] = []
    @Published var isShowingAddSheet = false
    @Published var isShowingOrigoActivationSheet = false
    @Published var isShowingAlert = false
    @Published var isSubmittingOrigoInvitationCode = false
    @Published var isShowingSwitchEnvironments = false
    @Published var selectedEnvironment: Environment?
    @Published var brivoConfig: BrivoSDKConfiguration?
    @Published var isEURegion = false {
        didSet {
            setRegion(isEURegion: isEURegion)
            brivoConfiguration()
        }
    }
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    @Published var passID = "".lowercased()
    @Published var passCode = ""
    @Published var origoInvitationCode = ""

    func onAppear() async {
        setRegion(isEURegion: isEURegion)
        brivoConfiguration()
        await getBrivoOnAirPasses()
        await refreshPasses()
    }

    func redeemPass() {
        Task {
            let result = try await BrivoSDKOnAir.instance().redeemPass(passId: self.passID,
                                                                       passCode: self.passCode)
            await MainActor.run {
                switch result {
                case .success:
                    brivoConfiguration()
                    Task {
                        await getBrivoOnAirPasses()
                    }
                    passID = ""
                    passCode = ""
                    isShowingAddSheet = false
                case .failure(let error):
                    onError(error)
                }
            }
        }
    }

#if canImport(BrivoHIDOrigo)
    func redeemOrigoInvitationCode() {
        Task { @MainActor in
            isSubmittingOrigoInvitationCode = true
            switch await BrivoSDKHIDOrigo.instance.redeem(invitationCode: origoInvitationCode) {
            case .success:
                isSubmittingOrigoInvitationCode = false
                isShowingOrigoActivationSheet = false
                origoInvitationCode = ""
            case .failure(let brivoError):
                isSubmittingOrigoInvitationCode = false
                alertTitle = "Brivo Error (code: \(brivoError.statusCode))"
                alertMessage = brivoError.errorDescription
                isShowingAlert = true
            }
        }
    }
#endif

    func resetPasses() {
        BrivoUserDefaults.setDictionary(value: [:], forKey: BrivoCore.Constants.KEY_PASSES)
        BrivoUserDefaults.setDictionary(value: [:], forKey: BrivoCore.Constants.KEY_PASSES_EU)
        self.brivoOnAirPasses = []
    }

    func refreshPasses() async {
        if brivoOnAirPasses.isEmpty {
            await getBrivoOnAirPasses()
        }
        refreshEachPass()
    }

    // MARK: - Private

    private func setRegion(isEURegion: Bool) {
        UserDefaultsAccessService().setRegion((isEURegion ? Region.eu : Region.us).rawValue)
    }

    private func brivoConfiguration() {
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
            self.alertTitle = "Brivo configuration error"
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
    }

    private func getBrivoOnAirPasses() async {
        do {
            let result = try await BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses()

            await MainActor.run {
                switch result {
                case .success(let brivoOnAirPasses):
                    self.brivoOnAirPasses = brivoOnAirPasses
#if canImport(BrivoHIDOrigo)
                    self.showOrigoActivationSheetIfNeeded()
#endif
                case .failure(let error):
                    onError(error)
                }
            }
        } catch (let error) {
            onError(error)
        }
    }    

    private func hasUserOrigoDoors() -> Bool {
        brivoOnAirPasses.contains { pass in
        pass.hasHidOrigoMobilePass && pass.sites?.contains { site in
            site.accessPoints?.contains { $0.readerType == .hidOrigo} ?? false
        } ?? false
    }
}

#if canImport(BrivoHIDOrigo)
    private func showOrigoActivationSheetIfNeeded() {
          Task { @MainActor in
              _  = await BrivoSDKHIDOrigo.instance.refresh()
              isShowingOrigoActivationSheet = hasUserOrigoDoors() && !BrivoSDKHIDOrigo.instance.isEndpointSetup()
          }
      }
#endif

#if canImport(BrivoBLEAllegion)
    private func getAllegionCredentialsIfPossible(_ brivoOnairPass: BrivoOnairPass?) {
        if let brivoOnairPass = brivoOnairPass, brivoOnairPass.hasAllegionBleCredentials {
            Task {
                let brivoSDKBLEAllegion = BrivoSDKBLEAllegion.instance
                try? await brivoSDKBLEAllegion.initialise()
                try? await brivoSDKBLEAllegion.refreshCredentials(brivoOnAirPass: brivoOnairPass)
            }
        }
    }
#endif

    private func deletePassIfNeeded(for error: BrivoError, passIndex: Int) {
        if error.isRefreshTokenError, brivoOnAirPasses.count > passIndex {
            brivoOnAirPasses.remove(at: passIndex)
        }
    }

    private func refreshEachPass() {
        for (index, brivoOnAirPass) in brivoOnAirPasses.enumerated() {
            if let tokens = brivoOnAirPass.brivoOnairPassCredentials?.tokens {
                Task {
                    let result = try await BrivoSDKOnAir.instance().refreshPass(brivoTokens: tokens)
                    await MainActor.run {
                        switch result {
                        case .success(let refreshedPass):
                            guard index < self.brivoOnAirPasses.count else {
                                return
                            }
                            if let refreshedPass = refreshedPass {
                                self.brivoOnAirPasses[index] = refreshedPass
#if canImport(BrivoBLEAllegion)
                                getAllegionCredentialsIfPossible(refreshedPass)
#endif
                            } else {
                                self.brivoOnAirPasses.remove(at: index)
                            }
                        case .failure(let error):
                            self.deletePassIfNeeded(for: error, passIndex: index)
                            onError(error)
                        }
                    }
                }
            }
        }
    }

    private func onError(_ error: Error) {
        guard let brivoError = error as? BrivoError else {
            alertTitle = "Error"
            alertMessage = "\(error.localizedDescription)"
            isShowingAlert = true
            return
        }
        alertTitle = "Error"
        alertMessage = brivoError.errorDescription + " " + "Status Code: \(brivoError.statusCode)"
        isShowingAlert = true
    }
}

// MARK: - Preview
#Preview {
    BrivoPassesView()
}
// swiftlint:enable line_length
