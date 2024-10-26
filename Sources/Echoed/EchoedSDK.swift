import Foundation
import Combine

public class EchoedSDK {
    public static let shared = EchoedSDK()
    
    public let networkManager: NetworkManager
    private let userTagManager: UserTagManager
    public var userTags: UserTagManager {
        return userTagManager
    }
    private let messageManager: MessageManager
    
    // Add publishers for tag updates
    private var tagDefinitionsSubject = PassthroughSubject<[NetworkManager.TagDefinition], Never>()
    public var tagDefinitions: AnyPublisher<[NetworkManager.TagDefinition], Never> {
        return tagDefinitionsSubject.eraseToAnyPublisher()
    }
    
    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
        messageManager = MessageManager()
    }
    
    public func initialize(apiKey: String, companyId: String) {
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
        fetchTagDefinitions()
    }
    
    // MARK: - Tag Definition Handling
    private func fetchTagDefinitions() {
        networkManager.fetchTagDefinitions { [weak self] result in
            switch result {
            case .success(let definitions):
                self?.tagDefinitionsSubject.send(definitions)
            case .failure(let error):
                print("Error fetching tag definitions: \(error)")
            }
        }
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
        userTagManager.setTag(key, value: value, type: type)
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
    }
    
    public func clearAllUserTags() {
        userTagManager.clearAllTags()
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
    
    // MARK: - Validation Helper
    private func validateInitialization() -> Result<Void, SDKError> {
        // Add any initialization validation logic here
        // For now, just return success
        return .success(())
    }
}

// MARK: - Helper Extensions
extension EchoedSDK {
    // Convenience method to set a tag with validation
    @discardableResult
    public func setTag(_ key: String, value: Any, type: UserTagManager.TagType) -> Result<Void, SDKError> {
        switch validateInitialization() {
        case .success:
            userTagManager.setTag(key, value: value, type: type)
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // Convenience method to get all tags as dictionary
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
