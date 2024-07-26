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

    var body: some View {
        List {
            if let accessPoints = stateModel.brivoSites.accessPoints {
                ForEach(accessPoints, id: \.id) { accessPoint in
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
                        Text(accessPoint.name ?? "")
                    }
                }
                .navigationTitle("Access Points for" + " " + (stateModel.brivoSites.siteName ?? ""))
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

class AccessPointViewModel {
    init(brivoOnAirPass: BrivoOnairPass, brivoSites: BrivoOnAir.BrivoSite) {
        self.brivoSites = brivoSites
        self.brivoOnAirPass = brivoOnAirPass
    }

    let brivoOnAirPass: BrivoOnairPass
    var brivoSites: BrivoOnAir.BrivoSite
}

#Preview {
    AccessPointView(stateModel: .init(brivoOnAirPass: .init(), brivoSites: .init()))
}
