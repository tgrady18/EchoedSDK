import UIKit

class MessageDisplayer {
    func display(_ message: Message, in viewController: UIViewController, completion: @escaping (String) -> Void) {
        switch message.type {
        case .multiChoice:
            guard let options = message.options else {
                completion("")
                return
            }
            displayMultiChoice(message, options: options, in: viewController, completion: completion)
        case .textInput:
            displayTextInput(message, in: viewController, completion: completion)
        }
    }
    
    private func displayMultiChoice(_ message: Message, options: [String], in viewController: UIViewController, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: message.title, message: message.content, preferredStyle: .alert)
        for option in options {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                completion(option)
            })
        }
        viewController.present(alert, animated: true)
    }
    
    private func displayTextInput(_ message: Message, in viewController: UIViewController, completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: message.title, message: message.content, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter your response"
        }
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
            if let response = alert.textFields?.first?.text {
                completion(response)
            } else {
                completion("")
            }
        })
        viewController.present(alert, animated: true)
    }
}

