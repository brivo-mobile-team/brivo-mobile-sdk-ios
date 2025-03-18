//
//  BrivoPassesView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI
import _PassKit_SwiftUI

// swiftlint:disable line_length

struct BrivoPassesView: View {
    @ObservedObject var viewModel: BrivoPassesViewModel
    
    var body: some View {
        List {
            if viewModel.brivoOnAirPassListItems.isEmpty {
                Text("You have no Passes. Please add passes by tapping the + button")
                    .accessibilityIdentifier(AccessibilityIds.noPassesTextView)
            } else {
                ForEach(viewModel.brivoOnAirPassListItems) { passItem in
                    listItem(passItem: passItem)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .refreshable { await viewModel.refreshPasses() }
        .navigationTitle(viewModel.brivoSDKVersion)
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.isShowingBrivoRedeemSheet.toggle()
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
        .sheet(isPresented: $viewModel.isShowingBrivoRedeemSheet) { addBrivoPassSheet }
        //Commented the code in case we continue with HID Origo wallet integration
        //Will remove if not needed
        //#if canImport(BrivoHIDOrigo)
        //.sheet(isPresented: $viewModel.isShowingOrigoActivationSheet) { addOrigoPassSheet }
        //#endif
        .onReceive(NotificationCenter.default.publisher(
            for: UIScene.willEnterForegroundNotification)) { _ in
                Task {
                    await viewModel.refreshPasses()
                }
            }
    }
    
    // MARK: - Private
    
    private func listItem(passItem: BrivoOnAirPassListItem) -> some View {
        Section {
            if let sites = passItem.onAirPass.sites {
                if sites.isEmpty {
                    Text("There are no sites assigned to you")
                }
                ForEach(sites, id: \.self) { site in
                    NavigationLink {
                        AccessPointView(
                            stateModel: .init(
                                brivoOnAirPass: passItem.onAirPass,
                                brivoSites: site
                            )
                        )
                    } label: {
                        Text(site.siteName ?? "")
                    }
                }
            }
        } header: {
            VStack(alignment: .leading) {
                Text("\(passItem.onAirPass.accountName ?? "")")
                    .accessibilityIdentifier(AccessibilityIds.accountNameTextView)
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
                            await viewModel.addToWallet(pass: passItem.onAirPass)
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
                Toggle(isOn: $viewModel.isEURegion) {
                    Text(viewModel.isEURegion ? "EU Region" : "US Region")
                }
                TextField("Pass ID", text: $viewModel.passID, prompt: Text("Pass ID"))
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(AccessibilityIds.mobilePassEmailField)
                TextField("Pass Code", text: $viewModel.passCode, prompt: Text("Pass Code"))
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
                        await viewModel.redeemPass()
                    }
                } label: {
                    if viewModel.isSubmittingBrivoPass {
                        ProgressView()
                    } else {
                        Text("Add Pass")
                            .accessibilityIdentifier(AccessibilityIds.redeemInviteButton)
                    }
                }
            }
            .disabled(viewModel.isSubmittingBrivoPass)
        }
        .presentationDetents([.fraction(0.30)])
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
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
            Picker("", selection: $viewModel.origoSelectedPassPickerItem) {
                ForEach(viewModel.origoPassPickerItems) { origoPassItem in
                    Text(origoPassItem.title)
                }
            }
            .pickerStyle(.wheel)
            .onAppear {
                viewModel.origoSelectedPassPickerItem = viewModel.origoPassPickerItems.first
            }
            Toggle("Wallet Integration", isOn: $viewModel.isOrigoWalletIntegrationEnabled)
            TextField("Origo Activation Code",
                      text: $viewModel.origoInvitationCode,
                      prompt: Text("Origo Activation Code"))
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
            .submitLabel(.done)
            .accessibilityIdentifier(AccessibilityIds.origoActivationCodeField)
            Button("Submit") {
                Task {
                    await viewModel.redeemOrigoInvitationCode()
                }
            }
            .accessibilityIdentifier(AccessibilityIds.origoRedeemButton)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(viewModel.origoInvitationCode.isEmpty)
        }
        .disabled(viewModel.isSubmittingOrigoInvitationCode)
        .padding()
        .overlay(origoLoadingOverlay)
        .presentationDetents([.fraction(0.4)])
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    private var origoLoadingOverlay: some View {
        if viewModel.isSubmittingOrigoInvitationCode {
            ProgressView().tint(.gray)
        }
    }
#endif
    
}

// MARK: - Preview

#Preview {
    BrivoPassesView(viewModel: BrivoPassesViewModel())
}
// swiftlint:enable line_length
