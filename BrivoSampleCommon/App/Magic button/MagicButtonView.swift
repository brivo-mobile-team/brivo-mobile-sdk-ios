//
//  MagicButtonView.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 29.09.2025.
//

import SwiftUI
import BrivoAccess
import BrivoCore

struct MagicButtonView: View {

    // MARK: - Properties
    @StateObject var viewModel: MagicButtonViewModel

    // MARK: - Body

    var body: some View {
        VStack{
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Readers")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(viewModel.displayedDevices) { device in
                                ReaderRow(device: device)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.openAccessPoint(for: device)
                                    }

                                if device.id != viewModel.displayedDevices.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    ScanningStatus(status: viewModel.currentStatus)
                        .padding(.top, 10)

                    Spacer(minLength: 120)
                }
                .padding(.top)
            }
            Spacer()
            FloatingUnlockButton(
                viewModel: viewModel
            ) {
                viewModel.openAccessPoint(for: viewModel.nearestDevice)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .alert(isPresented: $viewModel.isShowingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Nearby Readers")
        .task { viewModel.startScan() }
        .onDisappear {
            Task {
                viewModel.stopScan()
                viewModel.cancelUnlock()
            }
        }
    }
}

struct ReaderRow: View {
    let device: NearbyDevice

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.body)
                Text(device.id.description)
                Text(device.type.description)
            }
            Spacer()

            Text("RSSI: \(device.rssi)")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

struct ScanningStatus: View {
    let status: String

    var body: some View {
        HStack(spacing: 8) {
            if status == "scanning" {
                ProgressView()
            }
            Text(status)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

struct FloatingUnlockButton: View {
    let viewModel: MagicButtonViewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if viewModel.isShowingLoading {
                    ProgressView()
                } else {
                    viewModel.magicButtonImage
                        .resizable()
                        .frame(width: 30, height: 30)
                }

                Text(viewModel.magicButtonText)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(viewModel.isMagicButtonDisabled)
        .shadow(radius: 6)
    }
}
