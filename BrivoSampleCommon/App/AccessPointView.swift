//
//  AccessPointView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/14/24.
//

import SwiftUI
import BrivoAccess
import BrivoCore
import BrivoOnAir

struct AccessPointView: View {
    var stateModel: AccessPointViewModel

    // swiftlint:disable line_length
    var body: some View {
        List {
            if !stateModel.accessPoints.isEmpty {
                Section(header: Text("Brivo Access Points")) {
                    ForEach(stateModel.accessPoints, id: \.id) { accessPoint in
                        createNavigationLinkForAccessPoint(accessPoint)
                    }
                }
            }
            if !stateModel.origoAccessPoints.isEmpty {
                Section(header: Text("HID Origo Access Points")) {
                    ForEach(stateModel.origoAccessPoints, id: \.id) { accessPoint in
                        createNavigationLinkForAccessPoint(accessPoint)
                    }
                }
            }
        }
    }
    // swiftlint:enable line_length

    // MARK: - Private

    private func icon(_ accessPoint: BrivoAccessPoint) -> some View {
        Group {
            accessPoint.bluetoothReader != nil ? image("bluetooth") : image("wifi")
        }
    }

    private func image(_ name: String) -> some View {
        Image(name)
            .resizable().frame(width: 32.0, height: 32.0)
            .background(Color.white)
    }

    private func createNavigationLinkForAccessPoint(_ accessPoint: BrivoAccessPoint) -> some View {
        NavigationLink {
            if let userId = stateModel.brivoOnAirPass.brivoOnairPassCredentials?.userId,
               let doorType = accessPoint.doorType,
               let passId = stateModel.brivoOnAirPass.passId
            {
                UnlockAccessPointView(
                    stateModel: .init(
                        selectedAccessPoint: .init(
                            accessPointPath: .init(
                                accessPointId: accessPoint.id,
                                siteId: accessPoint.siteId,
                                passId: passId
                            ),
                            doorType: doorType,
                            passCredential: .init(
                                userId: userId,
                                tokens: stateModel.brivoOnAirPass.brivoOnairPassCredentials?.tokens
                            ),
                            isTwoFactorEnabled: accessPoint.twoFactorEnabled,
                            readerUid: accessPoint.bluetoothReader?.readerUid ?? accessPoint.controlLockSerialNumber,
                            bleCredentials: stateModel.brivoOnAirPass.bleCredential,
                            timeframe: stateModel.brivoOnAirPass.bleAuthTimeFrame,
                            deviceModelId: accessPoint.controlLockDeviceType
                        )
                    )
                )
            }
        } label: {
            HStack {
                icon(accessPoint)
                Text(accessPoint.name ?? "")
            }
        }
        .navigationTitle("Access Points for" + " " + (stateModel.brivoSites.siteName ?? ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}

class AccessPointViewModel {
    init(brivoOnAirPass: BrivoOnairPass, brivoSites: BrivoOnAir.BrivoSite) {
        self.brivoSites = brivoSites
        self.brivoOnAirPass = brivoOnAirPass
    }

    let brivoOnAirPass: BrivoOnairPass
    var brivoSites: BrivoOnAir.BrivoSite
    private(set) lazy var accessPoints: [BrivoAccessPoint] = { brivoSites.accessPoints?.filter { $0.doorType != .hidOrigo } ?? [] }()
    private(set) lazy var origoAccessPoints: [BrivoAccessPoint] = { brivoSites.accessPoints?.filter { $0.doorType == .hidOrigo } ?? [] }()
}

#Preview {
    AccessPointView(stateModel: .init(brivoOnAirPass: .init(), brivoSites: .init()))
}
