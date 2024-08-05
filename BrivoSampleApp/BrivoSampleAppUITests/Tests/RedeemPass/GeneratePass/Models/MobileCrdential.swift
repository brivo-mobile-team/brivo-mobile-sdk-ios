//
//  MobileCrdential.swift
//  BrivoSampleDevUITests
//
//  Created by Gabriel Dusa on 30.07.2024.
//

struct MobileCrdential: Codable {
    let credentials: [Credential]

    enum CodingKeys: String, CodingKey {
        case credentials = "data"
    }
}

struct Credential: Codable {
    let id: Int
    let referenceId: String
}

