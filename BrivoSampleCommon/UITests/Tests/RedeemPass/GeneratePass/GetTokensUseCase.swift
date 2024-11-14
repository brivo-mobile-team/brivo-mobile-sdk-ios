//
//  DefaultGetTokensUseCase.swift
//  BrivoPassPlusUITests
//
//  Created by Mihai Dorhan on 22.04.2024.
//

import Foundation
import BrivoCore
import BrivoNetworkCore

protocol GetTokensUseCase {
    mutating
    func execute() async throws -> BrivoTokens
}

enum GetTokensError: Error {
    case cannotGetAccessToken(reason: String)

    var errorDescription: String {
        switch self {
        case .cannotGetAccessToken(let reason):
            return reason
        }
    }
}

struct DefaultGetTokensUseCase: GetTokensUseCase {

    // MARK: - Properties

    private var brivoHTTPRequest: BrivoHTTPSRequest!

    // MARK: - GetTokensUseCase

    mutating
    func execute() async throws -> BrivoTokens {
        try await getToken()
    }

    // MARK: - Private

    mutating
    private func getToken() async throws -> BrivoTokens {
        try await withCheckedThrowingContinuation { continuation in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let body = GetTokensBody(audience: AutomationTestsConfiguration.configuration.audience,
                                     grantType: AutomationTestsConfiguration.configuration.grantType,
                                     username: AutomationTestsConfiguration.configuration.redeemPassConfig.username,
                                     password: AutomationTestsConfiguration.configuration.redeemPassConfig.password,
                                     scope: AutomationTestsConfiguration.configuration.scope,
                                     accountId: AutomationTestsConfiguration.configuration.accountId)
            let base64 = AutomationTestsConfiguration.configuration.basicAuthBase64
            let headers = ["Authorization": "Basic \(base64)",
                           "Content-type": "application/json"]
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.configuration.loginBaseUrl,
                                                    endPoint: "oauth/token",
                                                    method: .POST,
                                                    body: try? JSONEncoder().encode(body),
                                                    headers: headers)

            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard let tokens = BrivoTokens(dictionary: response?.dataDictionary) else {
                        continuation.resume(throwing: GetTokensError.cannotGetAccessToken(reason: "empty response data dictionary"))
                        return
                    }

                    continuation.resume(returning: tokens)
                } else {
                    continuation.resume(throwing: GetTokensError.cannotGetAccessToken(reason: response?.dataDictionary?.description ?? ""))
                }
            }
        }
    }
}
