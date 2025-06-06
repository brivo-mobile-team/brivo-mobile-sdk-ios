//
//  BrivoPassSheet.swift
//  BrivoSampleDev
//
//  Created by Paul Marc on 13.05.2025.
//

import SwiftUI

struct BrivoPassSheet: View {
    // MARK: - Properties

    @ObservedObject var viewModel: BrivoPassesViewModel
    var onAddPassAction: (() -> Void)

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
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

    // MARK: - Private

    private var content: some View {
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
            addPassButton
        }
        .disabled(viewModel.isSubmittingBrivoPass)
    }

    @ToolbarContentBuilder
    private var addPassButton: some ToolbarContent {
        ToolbarItem {
            Button {
                onAddPassAction()
            } label: {
                if viewModel.isSubmittingBrivoPass {
                    ProgressView()
                } else {
                    Text("Add Pass")
                        .accessibilityIdentifier(AccessibilityIds.redeemInviteButton)
                }
            }
        }
    }
}
