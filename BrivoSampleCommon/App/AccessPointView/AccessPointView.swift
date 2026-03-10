//
//  AccessPointView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/14/24.
//

import BrivoAccess
import BrivoCore
import BrivoOnAir
import SwiftUI

struct AccessPointView: View {
    @State var stateModel: AccessPointViewModel

    // swiftlint:disable line_length
    var body: some View {
        List {
            if !stateModel.accessPointItems.isEmpty {
                Section(header: Text("Brivo Access Points")) {
                    ForEach(stateModel.accessPointItems) { accessPoint in
                        makeNavigationLink(for: accessPoint)
                    }
                }
            }
            if !stateModel.origoAccessPointItems.isEmpty {
                Section(header: Text("HID Origo Access Points")) {
                    ForEach(stateModel.origoAccessPointItems, id: \.id) { accessPoint in
                        makeNavigationLink(for: accessPoint)
                    }
                }
            }
            if !stateModel.thermostatItems.isEmpty {
                Section(header: Text("Brivo Thermostats")) {
                    ForEach(stateModel.thermostatItems, id: \.id) { thermostat in
                        makeRowItem(for: thermostat)
                    }
                }
            }
        }
        .toolbar {
            Button {
                stateModel.shouldShowBottomSheet = true
            } label: {
                Image(systemName: "info.circle")
            }
            .accessibilityLabel("Site extended info button")
        }
        .sheet(isPresented: $stateModel.shouldShowBottomSheet) {
            ExtendedInfoSheet(title: "Site Informations", items: stateModel.siteExtendedDetails)
        }
    }

    // swiftlint:enable line_length

    // MARK: - Private

    private func makeNavigationLink(for accessPointItem: AccessPointItem) -> some View {
        NavigationLink {
            if let selectedAccessPoint = stateModel.selectedAccessPoint(for: accessPointItem) {
                let viewModel = AccessPointDetailsViewModel(selectedAccessPoint: selectedAccessPoint)
                AccessPointDetailsView(stateModel: viewModel)
            }
        }
        label: {
            HStack {
                accessPointItem.icon
                Text(accessPointItem.name)
            }
        }
        .navigationTitle("Access Points for" + " " + (stateModel.siteName))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func makeRowItem(for thermostat: ThermostatItem) -> some View {
        HStack {
            HStack(alignment: .top, spacing: 0) {
                thermostat.icon
                thermostat.onlineView
            }
            Text(thermostat.name)
            Spacer()
            Text(thermostat.temperature)
        }
    }
}

extension ThermostatItem {
    var icon: some View {
        Image(systemName: "thermometer.medium")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32.0, height: 32.0)
            .background(Color.white)
    }

    var onlineView: some View {
        Image(systemName: "inset.filled.circle")
            .resizable()
            .frame(width: 8.0, height: 8.0)
            .foregroundStyle(isOnline ? Color.green : Color.red)
    }
}

extension AccessPointItem {
    var icon: some View {
        Image(bleOpening ? .bluetooth : .wifi)
            .resizable()
            .frame(width: 32.0, height: 32.0)
            .background(Color.white)
    }
}

#Preview {
    NavigationStack {
        AccessPointView(stateModel: .init(brivoOnAirPass: .init(), brivoSite: .init()))
            .navigationTitle("Site example")
    }
}
