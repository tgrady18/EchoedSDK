//
//  UserTagManager.swift
//  Echoed
//
//  Created by Trevor (personal) on 2024-10-12.
//


import Foundation
import UIKit

public class UserTagManager {
    private let userDefaults = UserDefaults.standard
    private let tagsKey = "EchoedUserTags"
    
    // Internal tag keys
    private let firstSessionTimeKey = "first_session_time"
    private let sessionCountKey = "session_count"
    private let lastSessionTimeKey = "last_session_time"
    private let sessionTimeout: TimeInterval = 5

    public init() {
        initializeInternalTags()
        setupSessionTracking()
    }
    
    // MARK: - Internal Tags Initialization
    
    private func initializeInternalTags() {
        if getTag(firstSessionTimeKey) == nil {
            let currentTime = Date().timeIntervalSince1970
            setTag(firstSessionTimeKey, value: currentTime)
        }
        
        if getTag(sessionCountKey) == nil {
            setTag(sessionCountKey, value: 1) // Start with 1 since this is the first session
            setTag(lastSessionTimeKey, value: Date().timeIntervalSince1970)
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
        // Record the time when app goes to background
        let currentTime = Date().timeIntervalSince1970
        setTag(lastSessionTimeKey, value: currentTime)
    }
    
    private func incrementSessionCountIfNeeded() {
        let currentTime = Date().timeIntervalSince1970
        let lastSessionTime = getTag(lastSessionTimeKey) as? TimeInterval ?? 0
        
        // Check if the time since the last session is greater than time out
        if currentTime - lastSessionTime > sessionTimeout {
            let currentCount = getTag(sessionCountKey) as? Int ?? 0
            setTag(sessionCountKey, value: currentCount + 1)
        }
        
        // Update the last session time to the current time
        setTag(lastSessionTimeKey, value: currentTime)
    }
    
    // MARK: - Public Tag Methods
    
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
