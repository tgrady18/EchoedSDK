import Foundation
import UIKit

public class UserTagManager {
    private let userDefaults = UserDefaults.standard
    private let tagsKey = "EchoedUserTags"
    
    // Internal tag keys with their types
    private let internalTags: [String: TagType] = [
        "first_session_time": .timestamp,
        "session_count": .number,
        "last_session_time": .timestamp
    ]
    
    private let sessionTimeout: TimeInterval = 5
    
    public init() {
        initializeInternalTags()
        setupSessionTracking()
    }
    
    // MARK: - Tag Types
    public enum TagType: String, Codable {
        case number
        case string
        case timestamp
        case boolean
    }
    
    // MARK: - Internal Tags Initialization
    private func initializeInternalTags() {
        let currentTime = Date().timeIntervalSince1970
        
        if getTagValue("first_session_time") == nil {
            setTag("first_session_time", value: currentTime, type: .timestamp)
        }
        
        if getTagValue("session_count") == nil {
            setTag("session_count", value: 1, type: .number)
            setTag("last_session_time", value: currentTime, type: .timestamp)
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
        setTag("last_session_time", value: currentTime, type: .timestamp)
    }
    
    private func incrementSessionCountIfNeeded() {
        let currentTime = Date().timeIntervalSince1970
        let lastSessionTime = getTagValue("last_session_time") as? TimeInterval ?? 0
        
        // Check if the time since the last session is greater than timeout
        if currentTime - lastSessionTime > sessionTimeout {
            let currentCount = getTagValue("session_count") as? Int ?? 0
            setTag("session_count", value: currentCount + 1, type: .number)
        }
        
        // Update the last session time
        setTag("last_session_time", value: currentTime, type: .timestamp)
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
            if let intValue = value as? Int {
                return intValue
            }
            if let doubleValue = value as? Double {
                return doubleValue
            }
            return nil
        case .string:
            if let stringValue = value as? String {
                return stringValue
            }
            return nil
        case .timestamp:
            if let timeInterval = value as? TimeInterval {
                return timeInterval
            }
            if let date = value as? Date {
                return date.timeIntervalSince1970
            }
            return nil
        case .boolean:
            if let boolValue = value as? Bool {
                return boolValue
            }
            return nil
        }
    }
    
    // MARK: - Public Tag Methods
    public func setTag(_ key: String, value: Any, type: TagType) {
        guard validateValue(value, forType: type),
              let normalizedValue = normalizeValue(value, forType: type) else {
            print("Warning: Invalid value type for tag \(key)")
            return
        }
        
        var tags = getAllTags()
        tags[key] = [
            "value": normalizedValue,
            "type": type.rawValue
        ]
        userDefaults.set(tags, forKey: tagsKey)
    }
    
    public func getTagValue(_ key: String) -> Any? {
        guard let tagData = getAllTags()[key] as? [String: Any] else { return nil }
        return tagData["value"]
    }
    
    public func getTagType(_ key: String) -> TagType? {
        guard let tagData = getAllTags()[key] as? [String: Any],
              let typeString = tagData["type"] as? String else { return nil }
        return TagType(rawValue: typeString)
    }
    
    public func getAllTags() -> [String: Any] {
        return userDefaults.dictionary(forKey: tagsKey) ?? [:]
    }
    
    public func getAllTagsForNetwork() -> [String: Any] {
        var networkTags: [String: Any] = [:]
        let allTags = getAllTags()
        
        for (key, tagData) in allTags {
            guard let data = tagData as? [String: Any],
                  let value = data["value"] else { continue }
            networkTags[key] = value
        }
        
        return networkTags
    }
    
    public func removeTag(_ key: String) {
        // Don't allow removing internal tags
        guard !internalTags.keys.contains(key) else {
            print("Warning: Cannot remove internal tag \(key)")
            return
        }
        
        var tags = getAllTags()
        tags.removeValue(forKey: key)
        userDefaults.set(tags, forKey: tagsKey)
    }
    
    public func clearAllTags() {
        // Only clear non-internal tags
        var tags = getAllTags()
        let internalTagData = tags.filter { internalTags.keys.contains($0.key) }
        tags = internalTagData
        userDefaults.set(tags, forKey: tagsKey)
    }
    
    // MARK: - Debug Methods
    public func printAllTags() {
        let tags = getAllTags()
        print("Current Tags:")
        for (key, tagData) in tags {
            if let data = tagData as? [String: Any],
               let value = data["value"],
               let type = data["type"] as? String {
                print("Key: \(key), Value: \(value), Type: \(type)")
            }
        }
    }
}
