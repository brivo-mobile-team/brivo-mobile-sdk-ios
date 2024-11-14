//
//  UnlockAccessPointView.swift
//  BrivoSampleApp
//
//  Created by Thomas Prezioso on 3/13/24.
//

import SwiftUI
import BrivoCore
import BrivoBLE
import BrivoOnAir
import BrivoAccess

struct UnlockAccessPointView: View {
    @StateObject var stateModel: UnlockAccessPointViewModel
    var body: some View {
        Button {
            stateModel.openAccessPoint()
        } label: {
            Image(systemName: stateModel.isLocked ? "lock" : "lock.open")

                .tint(.primary)
            Text(stateModel.isLocked ? "Locked" : "Unlocked")
        }
        .padding()
        .background(stateModel.isLocked ? .red : .green)
        .foregroundColor(.white)
        .cornerRadius(10)
        .modifier(ActivityIndicatorModifier(isLoading: stateModel.isShowingLoading))
        .alert(isPresented: $stateModel.isShowingAlert) {
            Alert(
                title: Text(stateModel.alertTitle),
                message: Text(stateModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .toast(message: "Successfully Unlocked!", isShowing: $stateModel.isShowingToast, duration: Toast.long)
    }
}

#Preview {
    UnlockAccessPointView(stateModel: .init())
}

class UnlockAccessPointViewModel: ObservableObject {
    let selectedAccessPoint: BrivoSelectedAccessPoint?
    @Published var isShowingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLocked = true
    @Published var isShowingToast = false
    @Published var isShowingLoading = false

    init(selectedAccessPoint: BrivoSelectedAccessPoint? = nil,
         isShowingAlert: Bool = false,
         alertTitle: String = "",
         alertMessage: String = "",
         isLocked: Bool = true) {
        self.selectedAccessPoint = selectedAccessPoint
        self.isShowingAlert = isShowingAlert
        self.alertTitle = alertTitle
        self.alertMessage = alertMessage
        self.isLocked = isLocked
    }

    // swiftlint:disable line_length
    // swiftlint:disable function_body_length
    func openAccessPoint() {
        isShowingLoading = true
        setUnlockedTimer()
        let cancellationSignal = CancellationSignal()
        let timer = Timer(timeInterval: 10.0, repeats: false) {[weak self] (timer) in
            cancellationSignal.isCancelled = true
            self?.resetToInitialState()
            timer.invalidate()
        }

        let brivoSDKAccess = BrivoSDKAccess.instance()
        brivoSDKAccess.turnOnCentral()
        if let selectedAccessPoint = selectedAccessPoint {
            let passId = selectedAccessPoint.accessPointPath.passId
            let accessPointIdString = "\(selectedAccessPoint.accessPointPath.accessPointId)"
            Task {
                for try await result in await brivoSDKAccess.unlockAccessPoint(passId: passId,
                                                                               accessPointId: accessPointIdString,
                                                                               cancellationSignal: cancellationSignal) {
                    await MainActor.run {
                        if result.accessPointCommunicationState == .success {
                            timer.invalidate()
                            self.setLocked(isLocked: false)
                            self.isShowingToast = true
                            isShowingLoading = false
                        } else if result.accessPointCommunicationState == .failed {
                            timer.invalidate()
                            self.resetToInitialState()

                            if let error = result.error {
                                self.alertTitle = "Error"
                                self.alertMessage = (error.errorDescription) + " " + "Status Code: \(error.statusCode)"
                                self.isShowingAlert = true
                            }
                        }
                    }
                }
            }
        } else {
            Task {
                for try await result in await brivoSDKAccess.unlockNearestBLEAccessPoint(cancellationSignal: cancellationSignal) {
                    await MainActor.run {
                        switch result.accessPointCommunicationState {
                        case .success:
                            timer.invalidate()
                            self.setLocked(isLocked: false)
                            isShowingLoading = false
                        case .failed:
                            timer.invalidate()
                            self.resetToInitialState()
                            self.alertTitle = "Error"
                            self.alertMessage = (result.error?.errorDescription ?? "") + " " + "Status Code: \(result.error?.statusCode ?? 0)"
                            self.isShowingAlert = true
                        default:
                            break
                        }
                    }
                }
            }
        }
        RunLoop.current.add(timer, forMode: .common)
    }
    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

    private func resetToInitialState() {
        setLocked(isLocked: true)
        isShowingLoading = false
    }

    private func setLocked(isLocked: Bool) {
        self.isLocked = isLocked
    }

    private func setUnlockedTimer() {
        let timer = Timer(timeInterval: 30.0, repeats: false) {[weak self] (timer) in
            self?.setLocked(isLocked: true)
            timer.invalidate()
        }
        RunLoop.current.add(timer, forMode: .common)
    }
}

struct Toast: ViewModifier {

    static let short: TimeInterval = 2
    static let long: TimeInterval = 3.5

    let message: String
    @Binding var isShowing: Bool
    let config: Config

    func body(content: Content) -> some View {
        ZStack {
            toastView
            content
        }
    }

    private var toastView: some View {
        VStack {
            if isShowing {
                Group {
                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(config.textColor)
                        .font(config.font)
                        .padding(8)
                }
                .background(config.backgroundColor)
                .cornerRadius(8)
                .onTapGesture {
                    isShowing = false
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                        isShowing = false
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .animation(config.animation, value: isShowing)
        .transition(config.transition)
    }

    struct Config {
        let textColor: Color
        let font: Font
        let backgroundColor: Color
        let duration: TimeInterval
        let transition: AnyTransition
        let animation: Animation

        init(textColor: Color = .white,
             font: Font = .system(size: 14),
             backgroundColor: Color = .black.opacity(0.588),
             duration: TimeInterval = Toast.short,
             transition: AnyTransition = .opacity,
             animation: Animation = .linear(duration: 0.3)) {
            self.textColor = textColor
            self.font = font
            self.backgroundColor = backgroundColor
            self.duration = duration
            self.transition = transition
            self.animation = animation
        }
    }
}

extension View {
    func toast(message: String,
               isShowing: Binding<Bool>,
               config: Toast.Config) -> some View {
        self.modifier(Toast(message: message,
                            isShowing: isShowing,
                            config: config))
    }

    func toast(message: String,
               isShowing: Binding<Bool>,
               duration: TimeInterval) -> some View {
        self.modifier(Toast(message: message,
                            isShowing: isShowing,
                            config: .init(duration: duration)))
    }
}
