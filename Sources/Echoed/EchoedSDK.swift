import Foundation
import UIKit

public class EchoedSDK {
    public static let shared = EchoedSDK()
    
    private let networkManager: NetworkManager
    private let userTagManager: UserTagManager
    private let messageDisplayer: MessageDisplayer
    
    private init() {
        networkManager = NetworkManager()
        userTagManager = UserTagManager()
        messageDisplayer = MessageDisplayer()
    }
    
    public func initialize(apiKey: String, companyId: String) {
        networkManager.initialize(withApiKey: apiKey, companyId: companyId)
    }

    public func hitAnchor(_ anchorId: String, in viewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        let userTags = userTagManager.getAllTags()
        networkManager.fetchMessagesForAnchor(anchorId: anchorId, userTags: userTags) { [weak self] result in
            switch result {
            case .success(let messages):
                self?.displayMessages(messages, in: viewController, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func displayMessages(_ messages: [Message], in viewController: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !messages.isEmpty else {
            completion(.success(()))
            return
        }
        
        var remainingMessages = messages
        let message = remainingMessages.removeFirst()
        
        messageDisplayer.display(message, in: viewController) { [weak self] response in
            // Handle the response, e.g., send it back to the server
            self?.networkManager.sendMessageResponse(messageId: message.id, response: response) { _ in }
            // Display the next message
            self?.displayMessages(remainingMessages, in: viewController, completion: completion)
        }
    }
    
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
