import Foundation
import Combine

public class EchoedSDK {
    public static let shared = EchoedSDK()
    
    public let networkManager: NetworkManager
    private let userTagManager: UserTagManager
    public let deviceManager: DeviceManager  // New line
    public var userTags: UserTagManager {
        return userTagManager
    }
    private let messageManager: MessageManager
    
    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
        deviceManager = DeviceManager()  // New line
        messageManager = MessageManager()
    }
    
    public func initialize(apiKey: String, companyId: String) {
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
    }
    
    // MARK: - Anchor Methods
    public func hitAnchor(_ anchorId: String) {
        // Record anchor hit to the backend
        networkManager.recordAnchorHit(anchorId: anchorId) { result in
            switch result {
            case .success:
                print("Anchor hit recorded successfully")
            case .failure(let error):
                print("Error recording anchor hit: \(error)")
            }
        }
        
        // Fetch messages for this anchor
        networkManager.fetchMessagesForAnchor(anchorId: anchorId, userTags: userTags) { [weak self] result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self?.messageManager.present(messages: messages)
                }
            case .failure(let error):
                print("Error fetching messages: \(error)")
            }
        }
    }
    
    // MARK: - User Tag Methods
    public func setUserTag(_ key: String, value: Any, type: UserTagManager.TagType) {
        // Set locally
        userTagManager.setTag(key, value: value, type: type)
        
        // Sync with Firebase
        networkManager.updateTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                print("Tags synced with Firebase successfully")
            case .failure(let error):
                print("Error syncing tags with Firebase: \(error)")
            }
        }
    }
    
    public func getUserTagValue(_ key: String) -> Any? {
        return userTagManager.getTagValue(key)
    }
    
    public func getUserTagType(_ key: String) -> UserTagManager.TagType? {
        return userTagManager.getTagType(key)
    }
    
    public func getAllUserTags() -> [String: Any] {
        return userTagManager.getAllTagsForNetwork()
    }
    
    public func removeUserTag(_ key: String) {
        userTagManager.removeTag(key)
        // Sync removal with Firebase
        networkManager.updateTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                print("Tag removal synced with Firebase successfully")
            case .failure(let error):
                print("Error syncing tag removal with Firebase: \(error)")
            }
        }
    }
    
    public func clearAllUserTags() {
        userTagManager.clearAllTags()
        // Sync cleared tags with Firebase
        networkManager.updateTags(userTags: userTagManager) { result in
            switch result {
            case .success:
                print("Cleared tags synced with Firebase successfully")
            case .failure(let error):
                print("Error syncing cleared tags with Firebase: \(error)")
            }
        }
    }
    
    // MARK: - Debug Methods
    public func printAllTags() {
        userTagManager.printAllTags()
    }
    
    // MARK: - Error Types
    public enum SDKError: Error {
        case notInitialized
        case invalidTagType
        case tagValidationFailed
        case networkError(NetworkManager.NetworkError)
        
        var localizedDescription: String {
            switch self {
            case .notInitialized:
                return "SDK not properly initialized. Call initialize first."
            case .invalidTagType:
                return "Invalid tag type provided."
            case .tagValidationFailed:
                return "Tag validation failed. Check value type matches tag type."
            case .networkError(let error):
                return "Network error: \(error)"
            }
        }
    }
}

// MARK: - Helper Extensions
extension EchoedSDK {
    public func getTagsAsDictionary() -> [String: [String: Any]] {
        var result: [String: [String: Any]] = [:]
        let tags = userTagManager.getAllTags()
        
        for (key, value) in tags {
            if let tagData = value as? [String: Any],
               let tagValue = tagData["value"],
               let tagType = tagData["type"] as? String {
                result[key] = [
                    "value": tagValue,
                    "type": tagType
                ]
            }
        }
        
        return result
    }
}
