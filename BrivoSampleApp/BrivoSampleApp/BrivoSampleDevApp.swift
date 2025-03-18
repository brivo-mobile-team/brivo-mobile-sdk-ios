//
//  BrivoSampleAppApp.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI

@main
struct BrivoSampleDevApp: App {
    @StateObject var viewModel = BrivoPassesViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BrivoPassesView(viewModel: viewModel)
            }
        }
    }
}
