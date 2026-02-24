import Foundation
import UIKit
import os

class UserTagManager {
    private let userDefaults = UserDefaults.standard
    private let tagsKey = "EchoedUserTags"
    private let migrationKey = "EchoedTagsMigratedV2"

    private let reservedPrefix = "echoed_"

    private let sessionTimeout: TimeInterval = 5

    init() {
        migrateTagsIfNeeded()
        initializeInternalTags()
        setupSessionTracking()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Migration
    private func migrateTagsIfNeeded() {
        guard !userDefaults.bool(forKey: migrationKey) else { return }

        var tags = getAllTags()
        var migrated: [String: Any] = [:]

        let oldToNew: [String: String] = [
            "first_session_time": "echoed_first_session_time",
            "session_count": "echoed_session_count",
            "last_session_time": "echoed_last_session_time"
        ]

        for (key, tagData) in tags {
            guard var data = tagData as? [String: Any] else { continue }

            if let newKey = oldToNew[key] {
                data["category"] = TagCategory.internal.rawValue
                migrated[newKey] = data
            } else {
                if data["category"] == nil {
                    data["category"] = TagCategory.user.rawValue
                }
                migrated[key] = data
            }
        }

        userDefaults.set(migrated, forKey: tagsKey)
        userDefaults.set(true, forKey: migrationKey)
    }

    // MARK: - Internal Tags Initialization
    private func initializeInternalTags() {
        let currentTime = Date().timeIntervalSince1970

        if getTagValue("echoed_first_session_time") == nil {
            setTag("echoed_first_session_time", value: currentTime, type: .timestamp, category: .internal)
        }

        if getTagValue("echoed_session_count") == nil {
            setTag("echoed_session_count", value: 1, type: .number, category: .internal)
            setTag("echoed_last_session_time", value: currentTime, type: .timestamp, category: .internal)
        }
    }

    // MARK: - Session Tracking
    private func setupSessionTracking() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func appWillEnterForeground() {
        incrementSessionCountIfNeeded()
    }

    @objc private func appDidEnterBackground() {
        let currentTime = Date().timeIntervalSince1970
        setTag("echoed_last_session_time", value: currentTime, type: .timestamp, category: .internal)
    }

    private func incrementSessionCountIfNeeded() {
        let currentTime = Date().timeIntervalSince1970
        let lastSessionTime = getTagValue("echoed_last_session_time") as? TimeInterval ?? 0

        if currentTime - lastSessionTime > sessionTimeout {
            let currentCount = getTagValue("echoed_session_count") as? Int ?? 0
            setTag("echoed_session_count", value: currentCount + 1, type: .number, category: .internal)
        }

        setTag("echoed_last_session_time", value: currentTime, type: .timestamp, category: .internal)
    }

    // MARK: - Tag Validation
    private func validateValue(_ value: Any, forType type: TagType) -> Bool {
        switch type {
        case .number:
            return value is Int || value is Double
        case .string:
            return value is String
        case .timestamp:
            return value is TimeInterval || value is Date
        case .boolean:
            return value is Bool
        }
    }

    private func normalizeValue(_ value: Any, forType type: TagType) -> Any? {
        switch type {
        case .number:
            if let intValue = value as? Int { return intValue }
            if let doubleValue = value as? Double { return doubleValue }
            return nil
        case .string:
            if let stringValue = value as? String { return stringValue }
            return nil
        case .timestamp:
            if let timeInterval = value as? TimeInterval { return timeInterval }
            if let date = value as? Date { return date.timeIntervalSince1970 }
            return nil
        case .boolean:
            if let boolValue = value as? Bool { return boolValue }
            return nil
        }
    }

    // MARK: - Tag Methods
    func setTag(_ key: String, value: Any, type: TagType, category: TagCategory = .user) {
        guard validateValue(value, forType: type),
              let normalizedValue = normalizeValue(value, forType: type) else {
            EchoedSDK.logger.warning("Invalid value type for tag \(key)")
            return
        }

        var tags = getAllTags()
        tags[key] = [
            "value": normalizedValue,
            "type": type.rawValue,
            "category": category.rawValue
        ]
        userDefaults.set(tags, forKey: tagsKey)
    }

    func getTagValue(_ key: String) -> Any? {
        guard let tagData = getAllTags()[key] as? [String: Any] else { return nil }
        return tagData["value"]
    }

    func getTagType(_ key: String) -> TagType? {
        guard let tagData = getAllTags()[key] as? [String: Any],
              let typeString = tagData["type"] as? String else { return nil }
        return TagType(rawValue: typeString)
    }

    func getTagCategory(_ key: String) -> TagCategory? {
        guard let tagData = getAllTags()[key] as? [String: Any],
              let categoryString = tagData["category"] as? String else { return nil }
        return TagCategory(rawValue: categoryString)
    }

    func getAllTags() -> [String: Any] {
        return userDefaults.dictionary(forKey: tagsKey) ?? [:]
    }

    func getAllTagsForNetwork() -> [String: Any] {
        var networkTags: [String: Any] = [:]
        let allTags = getAllTags()

        for (key, tagData) in allTags {
            guard let data = tagData as? [String: Any],
                  let value = data["value"] else { continue }
            networkTags[key] = value
        }

        return networkTags
    }

    func removeTag(_ key: String) {
        let category = getTagCategory(key)
        guard category == .user || category == nil else {
            EchoedSDK.logger.warning("Cannot remove protected tag \(key)")
            return
        }

        var tags = getAllTags()
        tags.removeValue(forKey: key)
        userDefaults.set(tags, forKey: tagsKey)
    }

    func clearAllTags() {
        let tags = getAllTags()
        let protectedTags = tags.filter { key, tagData in
            guard let data = tagData as? [String: Any],
                  let catStr = data["category"] as? String,
                  let cat = TagCategory(rawValue: catStr) else { return false }
            return cat == .internal || cat == .customer
        }
        userDefaults.set(protectedTags, forKey: tagsKey)
    }

    // MARK: - Customer Methods
    func setCustomerTag(_ key: String, value: Any, type: TagType) {
        setTag(key, value: value, type: type, category: .customer)
    }

    func clearCustomerTags() {
        let tags = getAllTags()
        let remaining = tags.filter { key, tagData in
            guard let data = tagData as? [String: Any],
                  let catStr = data["category"] as? String else { return true }
            return catStr != TagCategory.customer.rawValue
        }
        userDefaults.set(remaining, forKey: tagsKey)
    }

    func getCustomerId() -> String? {
        return getTagValue("echoed_customer_id") as? String
    }

    /// Whether the `echoed_` prefix is reserved and should be rejected from `setUserTag`.
    func isReservedKey(_ key: String) -> Bool {
        return key.hasPrefix(reservedPrefix)
    }

    // MARK: - Debug Methods
    func printAllTags() {
        let tags = getAllTags()
        EchoedSDK.logger.debug("Current Tags:")
        for (key, tagData) in tags {
            if let data = tagData as? [String: Any],
               let value = data["value"],
               let type = data["type"] as? String {
                let category = data["category"] as? String ?? "unknown"
                EchoedSDK.logger.debug("Key: \(key), Value: \(String(describing: value)), Type: \(type), Category: \(category)")
            }
        }
    }
}
