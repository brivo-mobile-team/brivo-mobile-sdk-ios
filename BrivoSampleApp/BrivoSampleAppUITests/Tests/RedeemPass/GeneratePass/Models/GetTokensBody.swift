//
//  GetTokensBody.swift
//  BrivoPassPlusUITests
//
//  Created by Gabriel Dusa on 19.04.2024.
//

struct GetTokensBody: Codable {
    let audience: String
    let grantType: String
    let username: String
    let password: String
    let scope: String
    let accountId: Int

    enum CodingKeys: String, CodingKey {
        case audience
        case grantType = "grant_type"
        case username
        case password
        case scope
        case accountId = "account_id"
    }
}
