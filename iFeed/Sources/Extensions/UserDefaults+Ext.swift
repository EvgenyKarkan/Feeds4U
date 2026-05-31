//
//  UserDefaults+Ext.swift
//  iFeed
//
//  Created by Evgeny Karkan on 31.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

protocol KeyedStorageProtocol {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)

    func bool(forKey defaultName: String) -> Bool
    func set(_ value: Bool, forKey defaultName: String)

    func stringArray(forKey defaultName: String) -> [String]?

    func removeObject(forKey defaultName: String)
}

// MARK: - KeyedStorable
extension UserDefaults: KeyedStorageProtocol {}
