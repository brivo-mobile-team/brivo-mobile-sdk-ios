//
//  CancelPassUseCase.swift
//  BrivoSampleDevUITests
//
//  Created by Gabriel Dusa on 30.07.2024.
//

import Foundation
import BrivoCore
import BrivoNetworkCore

protocol CancelPassUseCase {
    mutating
    func execute(tokens: BrivoTokens) async throws
}

enum CancellPassError: Error {
    case cannotCancellPass
}

struct DefaultCancelPassUseCase: CancelPassUseCase {

    // MARK: - Properties

    private var brivoHTTPRequest: BrivoHTTPSRequest!

    // MARK: - GeneratePassUseCase

    mutating
    func execute(tokens: BrivoTokens) async throws {
        try await cancelPassPass(tokens: tokens)
    }

    // MARK: - Private

    mutating
    private func cancelPassPass(tokens: BrivoTokens) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            brivoHTTPRequest = BrivoHTTPSRequest()
            let headers = ["Authorization": "Bearer \(tokens.accessToken)",
                           "Content-type": "application/json"]
            let endpoint = "api/users/\(AutomationTestsConfiguration.configuration.redeemPassConfig.userId)/credentials/digital-invitations"
            let httpsRequestInfo = HTTPSRequestInfo(baseURLString: AutomationTestsConfiguration.configuration.apiBaseUrl,
                                                    endPoint: endpoint,
                                                    method: .DELETE,
                                                    body: nil,
                                                    headers: headers,
                                                    tokens: tokens)
            brivoHTTPRequest?.performRequest(requestInfo: httpsRequestInfo) { (response, _) in
                if response?.status?.error == nil {
                    guard (response?.data) != nil else {
                        continuation.resume(throwing: CancellPassError.cannotCancellPass)
                        return
                    }
                    continuation.resume()
                } else {
                    continuation.resume(throwing: CancellPassError.cannotCancellPass)
                }
            }
        }
    }
}
