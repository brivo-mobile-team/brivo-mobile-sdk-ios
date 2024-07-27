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

enum RevokePassError: Error {
    case cannotRevokePass
}

struct DefaultRevokePassUseCase: RevokePassUseCase {

    // MARK: - Properties

    var brivoHTTPRequest: BrivoHTTPSRequest!
    var getTokensUseCase = DefaultGetTokensUseCase()

    // MARK: - GeneratePassUseCase

    mutating
    func execute(credentialId: Int) async throws {
        let tokens = try await getTokensUseCase.execute()
        try await revokePass(tokens: tokens, credentialId: credentialId)
    }

    // MARK: - Private

    mutating
    private func revokePass(tokens: BrivoTokens, credentialId: Int) async throws -> RevokePassError? {
        try await withCheckedThrowingContinuation { continuation in
            brivoHTTPRequest = BrivoHTTPSRequest(timeoutIntervalForRequest: 60)
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.redeemPassConfig.userId)/credentials/\(credentialId)"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: "https://access.brivo.com/",
                                                    endPoint: endpoint,
                                                    method: .DELETE,
                                                    body: nil,
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard (response?.data) != nil else {
                        continuation.resume(throwing: RevokePassError.cannotRevokePass)
                        return
                    }
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(throwing: RevokePassError.cannotRevokePass)
                }
            }
        }
    }
}
