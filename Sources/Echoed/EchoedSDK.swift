import Foundation
import Combine

public class EchoedSDK: ObservableObject {
    public static let shared = EchoedSDK()
    
    private let networkManager: NetworkManager
    private let userTagManager: UserTagManager
    
    // Published property to hold messages to display
    @Published public var messagesToDisplay: [Message] = []
    
    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
    }
    
    public func initialize(apiKey: String, companyId: String) {
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
    }

    public func hitAnchor(_ anchorId: String) {
        let userTags = userTagManager.getAllTags()
        networkManager.fetchMessagesForAnchor(anchorId: anchorId, userTags: userTags) { [weak self] result in
            switch result {
            case .success(let messages):
                DispatchQueue.main.async {
                    self?.messagesToDisplay = messages
                }
            case .failure(let error):
                print("Error fetching messages: \(error)")
            }
        }
    }
    
    public func sendMessageResponse(messageId: String, response: String) {
        networkManager.sendMessageResponse(messageId: messageId, response: response) { result in
            switch result {
            case .success:
                print("Response sent successfully")
            case .failure(let error):
                print("Error sending response: \(error)")
            }
        }
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
