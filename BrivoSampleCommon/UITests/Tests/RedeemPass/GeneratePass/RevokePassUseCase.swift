//
//  RevokePassUseCase.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 22.04.2024.
//

import Foundation
import BrivoCore
import BrivoNetworkCore

protocol RevokePassUseCase {
    mutating
    func execute(credentialId: Int) async throws
}

struct DefaultRevokePassUseCase: RevokePassUseCase {

    // MARK: - Properties

    private var brivoHTTPRequest: BrivoHTTPSRequest!
    private var getTokensUseCase = DefaultGetTokensUseCase()

    // MARK: - RevokePassUseCase

    mutating
    func execute(credentialId: Int) async throws {
        let tokens = try await getTokensUseCase.execute()
        _ = try await revokePass(tokens: tokens, credentialId: credentialId)
    }

    // MARK: - Private

    mutating
    private func revokePass(tokens: BrivoTokens, credentialId: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.configuration.redeemPassConfig.userId)/credentials/\(credentialId)"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.configuration.apiBaseUrl,
                                                    endPoint: endpoint,
                                                    method: .DELETE,
                                                    body: nil,
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard (response?.data) != nil else {
                        continuation.resume(throwing: GeneratePassError.revokePass(reason: response?.dataDictionary?.description ?? ""))
                        return
                    }
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: GeneratePassError.revokePass(reason: response?.dataDictionary?.description ?? ""))
                }
            }
        }
    }
}
