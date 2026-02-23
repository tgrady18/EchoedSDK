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
        MessageDisplayer.shared.display(message) { [weak self] response in
            // Send response with message ID and user tags
            EchoedSDK.shared.networkManager.sendMessageResponse(
                messageId: message.id,
                response: response,
                userTags: EchoedSDK.shared.userTagManager
            ) { result in
                switch result {
                case .success:
                    EchoedSDK.logger.debug("Response sent successfully")
                case .failure(let error):
                    EchoedSDK.logger.error("Error sending response: \(error.localizedDescription)")
                }
            }
            self?.isPresenting = false
            self?.presentNextMessage()
        }
    }
}
