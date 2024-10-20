import Foundation
import Combine

public class EchoedSDK {
    public static let shared = EchoedSDK()
    
    public let networkManager: NetworkManager
    private let userTagManager: UserTagManager
    private let messageManager: MessageManager
    
    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
        messageManager = MessageManager()
    }
    
    public func initialize(apiKey: String, companyId: String) {
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
    }

    public func hitAnchor(_ anchorId: String) {
        let userTags = userTagManager.getAllTags()
        
        // Report anchor hit to the backend
        networkManager.recordAnchorHit(anchorId: anchorId) { result in
            switch result {
            case .success:
                print("Anchor hit recorded successfully")
            case .failure(let error):
                print("Error recording anchor hit: \(error)")
            }
        }
        
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

    
    public func getAllUserTags() -> [String: Any] {
        return userTagManager.getAllTags()
    }

    
    // User tag methods remain the same
    public func setUserTag(_ key: String, value: Any) {
        userTagManager.setTag(key, value: value)
    }
    
    public func getUserTag(_ key: String) -> Any? {
        return userTagManager.getTag(key)
    }
    
    public func removeUserTag(_ key: String) {
        userTagManager.removeTag(key)
    }
    
    public func clearAllUserTags() {
        userTagManager.clearAllTags()
    }
}
