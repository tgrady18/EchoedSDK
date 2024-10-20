import Foundation

class MessageManager {
    private var messageQueue: [Message] = []
    private var isPresenting = false
    
    func present(messages: [Message]) {
        guard !messages.isEmpty else { return }
        messageQueue.append(contentsOf: messages)
        presentNextMessage()
    }
    
    private func presentNextMessage() {
        guard !isPresenting, !messageQueue.isEmpty else { return }
        isPresenting = true
        let message = messageQueue.removeFirst()
        MessageDisplayer.shared.display(message) { response in
            // Get current user tags
            let userTags = EchoedSDK.shared.getAllUserTags()
            
            // Send response with message ID and user tags
            EchoedSDK.shared.networkManager.sendMessageResponse(messageId: message.id, response: response, userTags: userTags) { result in
                switch result {
                case .success:
                    print("Response sent successfully")
                case .failure(let error):
                    print("Error sending response: \(error)")
                }
            }
            self.isPresenting = false
            self.presentNextMessage()
        }
    }
}
