import SwiftUI

class MessageDisplayer {
    static let shared = MessageDisplayer()
    private var window: UIWindow?

    func display(_ message: Message, completion: @escaping (String) -> Void) {
        let hostingController = UIHostingController(rootView: MessageView(message: message, onResponse: { response in
            completion(response)
            self.dismiss()
        }))
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
            window?.rootViewController = hostingController
            window?.windowLevel = UIWindow.Level.alert + 1
            window?.makeKeyAndVisible()
        }
    }
    
    private func dismiss() {
        window?.isHidden = true
        window = nil
    }
}

struct MessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    
    var body: some View {
        VStack {
            Text(message.title)
                .font(.headline)
                .padding()
            Text(message.content)
                .font(.body)
                .padding()
            Spacer()
            switch message.type {
            case .multiChoice:
                MultiChoiceMessageView(message: message, options: message.options ?? [], onResponse: onResponse)
            case .textInput:
                TextInputMessageView(message: message, onResponse: onResponse)
            }
        }
    }
}

struct MultiChoiceMessageView: View {
    let message: Message
    let options: [String]
    let onResponse: (String) -> Void
    @State private var selectedOption: String?
    
    var body: some View {
        VStack {
            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            Button("Submit") {
                if let selectedOption = selectedOption {
                    onResponse(selectedOption)
                }
            }
            .disabled(selectedOption == nil)
            .padding()
        }
    }
}

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    @State private var userInput: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter your response", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Submit") {
                onResponse(userInput)
            }
            .disabled(userInput.isEmpty)
            .padding()
        }
    }
}
