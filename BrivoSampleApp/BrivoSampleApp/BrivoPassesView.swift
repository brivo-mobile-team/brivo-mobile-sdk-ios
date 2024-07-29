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

struct BrivoPassesView: View {
    @StateObject var stateModel = BrivoPassesViewModel()

    var body: some View {
        NavigationStack {
            List {
                if stateModel.brivoOnAirPasses.isEmpty {
                    Text("You have no Passes. Please add passes by tapping the + button")
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
                stateModel.onAppear()
            }
            .refreshable { stateModel.refreshPasses() }
            .navigationTitle("BrivoSDK \(BrivoSDK.sdkVersion)")
            .toolbar {
                ToolbarItem {
                    Button {
                        stateModel.isShowingAddSheet.toggle()
                    } label: {
                        Image(systemName: "plus").accessibilityIdentifier(AccessibilityIds.navigationPlusButton)
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
            .sheet(isPresented: $stateModel.isShowingAddSheet) {
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
        }
    }
}

#Preview {
    BrivoPassesView()
}

class BrivoPassesViewModel: ObservableObject {
    @Published var brivoOnAirPasses: [BrivoOnairPass] = []
    @Published var isShowingAddSheet = false
    @Published var isShowingAlert = false
    @Published var isEURegion = false {
        didSet {
            brivoConfiguration()
        }
    }
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    @Published var passID = "".lowercased()
    @Published var passCode = ""

    func onAppear() {
        brivoConfiguration()
        getBrivoOnAirPasses()
        refreshPasses()
    }

    private func brivoConfiguration() {
        do {
            let brivoConfiguration = try BrivoSDKConfiguration(
                clientId: self.isEURegion ? Constants.EU_CLIENT_ID : Constants.CLIENT_ID,
                clientSecret: self.isEURegion ? Constants.EU_CLIENT_SECRET : Constants.CLIENT_SECRET,
                useSDKStorage: true,
                useEURegion: self.isEURegion
            )
            BrivoSDK.instance.configure(brivoConfiguration: brivoConfiguration)

        } catch let error {
            self.alertTitle = "Brivo configuration error"
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
    }

    private func getBrivoOnAirPasses() {
        do {
            try BrivoSDKOnAir.instance().retrieveSDKLocallyStoredPasses(
                onSuccess: { [weak self] brivoOnAirPasses in
                    self?.brivoOnAirPasses = brivoOnAirPasses
                }, onFailure: {[weak self] (brivoError) in
                    self?.alertTitle = "Error"
                    self?.alertMessage = brivoError.errorDescription + " " + "Status Code: \(brivoError.statusCode)"
                    self?.isShowingAlert = true
                })
        } catch let error {
            self.alertTitle = error.localizedDescription
            self.isShowingAlert = true
        }
    }

    func redeemPass() {
        do {
            try BrivoSDKOnAir.instance().redeemPass(
                passId: self.passID,
                passCode: self.passCode,
                onSuccess: { [weak self] _ in
                    self?.brivoConfiguration()
                    self?.getBrivoOnAirPasses()
                    self?.passID = ""
                    self?.passCode = ""
                    self?.isShowingAddSheet = false
                },
                onFailure: { [weak self] brivoError in
                    self?.alertTitle = "Error"
                    self?.alertMessage = "\(brivoError.errorDescription) Status Code: \(brivoError.statusCode)"
                    self?.isShowingAlert = true
                }
            )
        } catch let error {
            self.alertTitle = "Brivo configuration error"
            self.alertMessage = error.localizedDescription
            self.isShowingAlert = true
        }
    }

    func refreshPasses() {
        if brivoOnAirPasses.isEmpty {
            getBrivoOnAirPasses()
        } else {
            for (index, brivoOnAirPass) in brivoOnAirPasses.enumerated() {
                do {
                    if let tokens = brivoOnAirPass.brivoOnairPassCredentials?.tokens {
                        try BrivoSDKOnAir.instance().refreshPass(
                            brivoTokens: tokens,
                            onSuccess: {
                                [weak self] (refreshedPass) in
                                guard index < (self?.brivoOnAirPasses.count ?? 0) else {
                                    return
                                }
                                if let refreshedPass = refreshedPass {
                                    self?.brivoOnAirPasses[index] = refreshedPass
                                } else {
                                    self?.brivoOnAirPasses.remove(at: index)
                                }
                            },
                            onFailure: { [weak self] responseStatus in
                                self?.alertTitle = "Error"
                                self?.alertMessage = responseStatus.errorDescription + " " + "Status Code: \(responseStatus.statusCode)"
                                self?.isShowingAlert = true
                            }
                        )
                    }
                } catch let error {
                    self.alertTitle = "Brivo configuration error"
                    self.alertMessage = error.localizedDescription
                    self.isShowingAlert = true                }
            }
        }
    }
}
