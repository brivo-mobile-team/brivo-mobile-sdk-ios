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
    case cannotGetAccessToken
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
            let body = GetTokensBody(audience: AutomationTestsConfiguration.audience,
                                     grantType: AutomationTestsConfiguration.grantType,
                                     username: AutomationTestsConfiguration.redeemPassConfig.username,
                                     password: AutomationTestsConfiguration.redeemPassConfig.password,
                                     scope: AutomationTestsConfiguration.scope,
                                     accountId: AutomationTestsConfiguration.accountId)
            let base64 = AutomationTestsConfiguration.basicAuthBase64
            let headers = ["Authorization": "Basic \(base64)",
                           "Content-type": "application/json"]
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.loginBaseUrl,
                                                    endPoint: "oauth/token",
                                                    method: .POST,
                                                    body: try? JSONEncoder().encode(body),
                                                    headers: headers)

            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard let tokens = BrivoTokens(dictionary: response?.dataDictionary) else {
                        continuation.resume(throwing: GetTokensError.cannotGetAccessToken)
                        return
                    }

                    continuation.resume(returning: tokens)
                } else {
                    continuation.resume(throwing: GetTokensError.cannotGetAccessToken)
                }
            }
        }
    }
}
