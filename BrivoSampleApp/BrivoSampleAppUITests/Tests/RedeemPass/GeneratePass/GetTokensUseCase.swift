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

    var brivoHTTPRequest: BrivoHTTPSRequest!

    // MARK: - GeneratePassUseCase

    mutating
    func execute() async throws -> BrivoTokens {
        try await getToken()
    }

    // MARK: - Private

    mutating
    private func getToken() async throws -> BrivoTokens {
        try await withCheckedThrowingContinuation { continuation in
            brivoHTTPRequest = BrivoHTTPSRequest(timeoutIntervalForRequest: 60)
            let body = GetTokensBody(audience: "https://api.brivo.com",
                                     grantType: "password",
                                     username: AutomationTestsConfiguration.redeemPassConfig.username,
                                     password: AutomationTestsConfiguration.redeemPassConfig.password,
                                     scope: "openid",
                                     accountId: 1861040)
            let base64 = "WDerz2RAdLj1DBEHFlQpKCaLOp9EmN2B:EQD6YifgIj3QSQX38g-pT5_AM1TrNocdCaocncZlrfHmTp6jIdccBEXekjsY_GvC".toBase64() ?? ""
            let headers = ["Authorization": "Basic \(base64)",
                           "Content-type": "application/json"]
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: "https://login.brivo.com/",
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
