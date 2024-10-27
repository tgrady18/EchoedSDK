//
//  DeviceManager.swift
//  Echoed
//
//  Created by Trevor Grady on 2024-10-27.
//
import Foundation


public class DeviceManager {
    private let userDefaults = UserDefaults.standard
    private let deviceIdKey = "EchoedDeviceId"
    
    public init() {
        // Ensure device ID exists on initialization
        _ = getDeviceId()
    }
    
    public func getDeviceId() -> String {
        if let existingId = userDefaults.string(forKey: deviceIdKey) {
            return existingId
        }
        
        let newId = UUID().uuidString
        userDefaults.set(newId, forKey: deviceIdKey)
        return newId
    }
}
