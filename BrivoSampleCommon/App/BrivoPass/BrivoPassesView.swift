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
            if viewModel.shouldShowEmptyView {
                emptyView
            } else {
                passFeed
            }
        }
        .task {
            await viewModel.refreshPasses()
        }
        .refreshable {
            await viewModel.refreshPasses()
        }
        .navigationTitle(viewModel.brivoSDKVersion)
        .toolbar {
            toolBar
        }
        .sheet(isPresented: $viewModel.isShowingBrivoRedeemSheet) {
            brivoPassSheet
        }
        .alert(isPresented: $viewModel.isShowingAlert) { alert }
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
            header(passItem: passItem)
        } footer: {
            #if canImport(BrivoHIDOrigo)
            footer(passItem: passItem)
            #endif
        }
    }

    @ToolbarContentBuilder
    private var toolBar: some ToolbarContent {
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

    private var emptyView: some View {
        Text("You have no Passes. Please add passes by tapping the + button")
            .accessibilityIdentifier(AccessibilityIds.noPassesTextView)
    }

    private var passFeed: some View {
        ForEach(viewModel.brivoOnAirPassListItems) { passItem in
            listItem(passItem: passItem)
        }
    }

    private func header(passItem: BrivoOnAirPassListItem) -> some View {
        VStack(alignment: .leading) {
            Text("\(passItem.onAirPass.accountName ?? "")")
                .accessibilityIdentifier(AccessibilityIds.accountNameTextView)
            Text("Account ID: \(passItem.onAirPass.accountId)")
            Text("\(passItem.onAirPass.firstName ?? "") \(passItem.onAirPass.lastName ?? "")")
            Text("Pass ID: \(passItem.onAirPass.passId ?? "")")
        }
    }

#if canImport(BrivoHIDOrigo)
    private func footer(passItem: BrivoOnAirPassListItem) -> some View {
        HIDOrigoFooterView(passItem: passItem, addToWalletAction: {
            Task {
                await viewModel.addToWallet(pass: passItem.onAirPass)
            }
        })
    }
#endif

    @ViewBuilder
    private var brivoPassSheet: some View {
        BrivoPassSheet(viewModel: viewModel, onAddPassAction: {
            Task {
                await viewModel.redeemPass()
            }
        })
    }

    private var alert: Alert {
        Alert(
            title: Text(viewModel.alertTitle),
            message: Text(viewModel.alertMessage),
            dismissButton: .default(Text("OK"))
        )
    }
}

// MARK: - Preview

#Preview {
    BrivoPassesView(viewModel: BrivoPassesViewModel())
}
// swiftlint:enable line_length
