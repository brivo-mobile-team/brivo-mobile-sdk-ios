//
//  CleanupPassUseCase.swift
//  BrivoSampleDevUITests
//
//  Created by Gabriel Dusa on 30.07.2024.
//

import Foundation
import BrivoCore
import BrivoNetworkCore

protocol CleanupPassUseCase {
    mutating
    func execute() async throws
}

class DefaultCleanupPassUseCase: CleanupPassUseCase {

    // MARK: - Properties

    private var brivoHTTPRequest: BrivoHTTPSRequest!
    private var getTokensUseCase = DefaultGetTokensUseCase()
    private var revokePassUseCase = DefaultRevokePassUseCase()
    private var cancelPassUseCase = DefaultCancelPassUseCase()

    // MARK: - CleanupPassUseCase

    func execute() async throws {
        let tokens = try await getTokensUseCase.execute()
        try await revokeActivePass(tokens: tokens)
        try await cancelPassInvitation(tokens: tokens)
    }

    // MARK: - Private

    private func revokeActivePass(tokens: BrivoTokens) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.redeemPassConfig.userId)/credentials"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.apiBaseUrl,
                                                    endPoint: endpoint,
                                                    method: .GET,
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { [weak self] (response, _) in
                guard let self = self, let mobilePass = self.onCredentialsResponse(response) else {
                    continuation.resume(returning: ())
                    return
                }
                Task {
                    do {
                        try await self.revokePassUseCase.execute(credentialId: mobilePass.id)
                    } catch {
                        continuation.resume(throwing: GeneratePassError.revokePass(reason: error.localizedDescription))
                    }
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func cancelPassInvitation(tokens: BrivoTokens) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.redeemPassConfig.userId)/credentials/digital-invitations"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.apiBaseUrl,
                                                    endPoint: endpoint,
                                                    method: .GET,
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { [weak self] (response, _) in
                guard let self = self, let _ = self.onCredentialsResponse(response) else {
                    continuation.resume(returning: ())
                    return
                }
                Task {
                    do {
                        try await self.cancelPassUseCase.execute(tokens: tokens)
                    } catch {
                        continuation.resume(throwing: GeneratePassError.cancelPass(reason: error.localizedDescription))
                    }
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func onCredentialsResponse(_ response: BrivoOnAirResponse?) -> Credential? {
        if let data = response?.data, let mobilePasses = try? JSONDecoder().decode(MobileCrdential.self, from: data), let mobilePass = mobilePasses.credentials.first {
            return mobilePass
        } else {
            return nil
        }
    }
}
