//
//  UserTagManager.swift
//  Echoed
//
//  Created by Trevor (personal) on 2024-10-12.
//


import Foundation

public class UserTagManager {
    private let userDefaults = UserDefaults.standard
    private let tagsKey = "EchoedUserTags"

    public func setTag(_ key: String, value: Any) {
        var tags = getAllTags()
        tags[key] = value
        userDefaults.set(tags, forKey: tagsKey)
    }

    public func getTag(_ key: String) -> Any? {
        return getAllTags()[key]
    }

    public func getAllTags() -> [String: Any] {
        return userDefaults.dictionary(forKey: tagsKey) ?? [:]
    }

    public func removeTag(_ key: String) {
        var tags = getAllTags()
        tags.removeValue(forKey: key)
        userDefaults.set(tags, forKey: tagsKey)
    }

    public func clearAllTags() {
        userDefaults.removeObject(forKey: tagsKey)
    }
}
