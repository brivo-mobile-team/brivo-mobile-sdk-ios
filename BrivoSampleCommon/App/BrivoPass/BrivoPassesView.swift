//
//  BrivoPassesView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI
import BrivoOnAir

struct BrivoPassesView: View {
    
    //MARK: - Properties
    
    @ObservedObject var viewModel: BrivoPassesViewModel
    @State var shouldShowCopyToast = false
    
    //MARK: - Body
    
    var body: some View {
        VStack {
            if viewModel.shouldShowEmptyView {
                emptyView
            } else {
                passView
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
        .sheet(isPresented: $viewModel.shouldShowDetailsBottomSheet) {
            ExtendedInfoSheet(title: "Pass info", items: viewModel.passExtendedDetails)
        }
        .toast(
            message: "Copied to clipboard",
            isShowing: $shouldShowCopyToast,
            duration: Toast.short
        )
        .alert(isPresented: $viewModel.isShowingAlert) { alert }
        .onReceive(NotificationCenter.default.publisher(
            for: UIScene.willEnterForegroundNotification)) { _ in
                Task {
                    await viewModel.refreshPasses()
                }
            }
    }

    // MARK: - Private
    
    private var passView: some View {
        List {
            ForEach(viewModel.brivoOnAirPassListItems, id: \.self) { passUIModel in
                Section {
                    InfoRow(key: "Account Name", value: passUIModel.onAirPass.accountName ?? "-", showToast: $shouldShowCopyToast)
                    InfoRow(key: "Account ID",   value: "\(passUIModel.onAirPass.accountId)", showToast: $shouldShowCopyToast)
                    InfoRow(key: "User Name",    value: "\(passUIModel.onAirPass.firstName ?? "") \(passUIModel.onAirPass.lastName ?? "")", showToast: $shouldShowCopyToast)
                    InfoRow(key: "Pass ID",      value:  "\(passUIModel.onAirPass.passId ?? "")", showToast: $shouldShowCopyToast)
                } header: {
                    HeaderWithInfo(title: "Pass details") {
                        viewModel.getPassUIModel(passItem: passUIModel)
                        viewModel.shouldShowDetailsBottomSheet = true }
                }
                .onAppear {
                    viewModel.getPassUIModel(passItem: passUIModel)
                }
                listItem(passItem: passUIModel)
            }
        }
        .listStyle(.insetGrouped)
        
    }

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
                                brivoSite: site
                            )
                        )
                    } label: {
                        Text(site.siteName ?? "")
                    }
                }
            }
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
                AccessPointDetailsView(stateModel: .init())
            } label: {
                Text("Magic Button")
            }
        }
    }

    private var emptyView: some View {
        Text("You have no Passes. Please add passes by tapping the + button")
            .padding(.horizontal, 10)
            .multilineTextAlignment(.center)
            .accessibilityIdentifier(AccessibilityIds.noPassesTextView)
    }

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
