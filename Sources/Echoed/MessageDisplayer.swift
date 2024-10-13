import SwiftUI

class MessageDisplayer {
    func display(_ message: Message, completion: @escaping (String) -> Void) -> AnyView {
        switch message.type {
        case .multiChoice:
            guard let options = message.options else {
                completion("")
                return AnyView(EmptyView())
            }
            return AnyView(MultiChoiceMessageView(message: message, options: options, onResponse: completion))
        case .textInput:
            return AnyView(TextInputMessageView(message: message, onResponse: completion))
        }
    }
}


struct MultiChoiceMessageView: View {
    let message: Message
    let options: [String]
    let onResponse: (String) -> Void
    @State private var selectedOption: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message.title)
                .font(.headline)
            Text(message.content)
                .font(.body)
            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            Button("Submit") {
                if let selectedOption = selectedOption {
                    onResponse(selectedOption)
                }
            }
            .disabled(selectedOption == nil)
        }
        .padding()
    }
}

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    @State private var userInput: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(message.title)
                .font(.headline)
            Text(message.content)
                .font(.body)
            TextField("Enter your response", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Submit") {
                onResponse(userInput)
            }
            .disabled(userInput.isEmpty)
        }
        .padding()
    }
}
