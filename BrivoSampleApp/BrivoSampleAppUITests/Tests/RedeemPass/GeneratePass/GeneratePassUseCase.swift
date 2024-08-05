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
    case cannotGeneratePass(reason: String)
    case revokePass(reason: String)
    case cancelPass(reason: String)
}

class DefaultGeneratePassUseCase: GeneratePassUseCase {

    // MARK: - Properties

    private var brivoHTTPRequest: BrivoHTTPSRequest!
    private var getTokensUseCase = DefaultGetTokensUseCase()
    private var cleanupPassUseCase = DefaultCleanupPassUseCase()

    // MARK: - GeneratePassUseCase

    func execute() async throws -> MobilePass {
        let tokens = try await getTokensUseCase.execute()
        return try await sendPass(tokens: tokens)
    }

    // MARK: - Private

    private func sendPass(tokens: BrivoTokens) async throws -> MobilePass {
        try await self.cleanupPassUseCase.execute()
        return try await withCheckedThrowingContinuation { continuation in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let body = SendPassBody(referenceId: AutomationTestsConfiguration.redeemPassConfig.referenceId)
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.redeemPassConfig.userId)/credentials/digital-invitations"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.apiBaseUrl,
                                                    endPoint: endpoint,
                                                    method: .POST,
                                                    body: try? JSONEncoder().encode(body),
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard let data = response?.data, let mobilePass = try? JSONDecoder().decode(MobilePass.self, from: data) else {
                        continuation.resume(throwing: GeneratePassError.cannotGeneratePass(reason: response?.dataDictionary?.description ?? ""))
                        return
                    }
                    continuation.resume(returning: mobilePass)
                } else {
                    continuation.resume(throwing: GeneratePassError.cannotGeneratePass(reason: response?.dataDictionary?.description ?? ""))
                }
            }
        }
    }
}
