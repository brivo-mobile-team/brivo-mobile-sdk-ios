//
//  UserDefaultsAccessService.swift
//  BrivoSampleDev
//
//  Created by Adrian Somesan on 09.09.2024.
//

import Foundation
import BrivoCore

enum UserDefaultsKeys {
    static let region = "region"
}

protocol IUserDefaultsAccessService {
    func getRegion() -> Int?
    func setRegion(_ region: Int)
}

class UserDefaultsAccessService: IUserDefaultsAccessService {

    // MARK: - Properties

    private let sharedUserDefaults = UserDefaults()

    // MARK: - UserDefaultsAccessService

    func setRegion(_ region: Int) {
        storeData(region,
                  key: UserDefaultsKeys.region)
    }

    func getRegion() -> Int? {
        getData(key: UserDefaultsKeys.region) ?? Region.us.rawValue
    }

    func getData<T: Decodable>(key: String) -> T? {
        if let data = sharedUserDefaults.data(forKey: key) {
            let jsonDecoder = JSONDecoder()
            do {
                return try jsonDecoder.decode(T.self, from: data)
            } catch {
                return nil
            }
        }
        return nil
    }

    func storeData<T: Encodable>(_ data: T, key: String) {
        do {
            let jsonEncoder = JSONEncoder()
            let encoded = try jsonEncoder.encode(data)
            sharedUserDefaults.set(encoded, forKey: key)
        } catch {
            sharedUserDefaults.set(nil, forKey: key)
        }
    }
}
