//
//  GeneratePassUseCase.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 19.04.2024.
//

import Foundation
import BrivoCore
import BrivoNetworkCore

protocol GeneratePassUseCase {
    mutating
    func execute() async throws -> MobilePass
}

enum GeneratePassError: Error {
    case cannotGeneratePass
    case needToRevokePass
}

class DefaultGeneratePassUseCase: GeneratePassUseCase {

    // MARK: - Properties

    var brivoHTTPRequest: BrivoHTTPSRequest!
    var getTokensUseCase = DefaultGetTokensUseCase()
    var revokePassUseCase = DefaultRevokePassUseCase()

    // MARK: - GeneratePassUseCase

    func execute() async throws -> MobilePass {
        let tokens = try await getTokensUseCase.execute()
        return try await sendPass(tokens: tokens)
    }

    // MARK: - Private

    private func sendPass(tokens: BrivoTokens) async throws -> MobilePass {
        try await withCheckedThrowingContinuation { continuation in
            brivoHTTPRequest = BrivoHTTPSRequest(timeoutIntervalForRequest: 60)
            let body = SendPassBody(referenceId: AutomationTestsConfiguration.redeemPassConfig.referenceId)
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.redeemPassConfig.userId)/credentials/digital-invitations"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: "https://access.brivo.com/",
                                                    endPoint: endpoint,
                                                    method: .POST,
                                                    body: try? JSONEncoder().encode(body),
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard let data = response?.data, let mobilePass = try? JSONDecoder().decode(MobilePass.self, from: data) else {
                        continuation.resume(throwing: GeneratePassError.cannotGeneratePass)
                        return
                    }
                    continuation.resume(returning: mobilePass)
                } else {
                    // Based on the error we get we need to either:
                    // - cancel the invitation
                    // - revoke pass
                    if response?.status?.statusCode == 409 {
                        continuation.resume(throwing: GeneratePassError.needToRevokePass)
                    } else {
                        continuation.resume(throwing: GeneratePassError.cannotGeneratePass)
                    }
                }
            }
        }
    }
}
