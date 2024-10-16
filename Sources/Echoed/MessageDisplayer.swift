import SwiftUI

class MessageDisplayer {
    static let shared = MessageDisplayer()
    private var window: UIWindow?
    
    func display(_ message: Message, completion: @escaping (String) -> Void) {
        DispatchQueue.main.async { [weak self] in
            let hostingController = UIHostingController(rootView: MessageView(message: message, onResponse: { response in
                completion(response)
                self?.dismiss()
            }))
            
            // Find the current active window scene
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self?.window = UIWindow(windowScene: scene)
                self?.window?.rootViewController = hostingController
                self?.window?.windowLevel = UIWindow.Level.alert + 1
                self?.window?.makeKeyAndVisible()
            } else {
                print("No active UIWindowScene found.")
            }
        }
    }
    
    private func dismiss() {
        DispatchQueue.main.async { [weak self] in
            self?.window?.isHidden = true
            self?.window = nil
        }
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
        VStack(spacing: 20) {
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
        VStack(spacing: 20) {
            Text(message.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 20)
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            TextField("Enter your response", text: $userInput)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 20)
            
            Button(action: {
                onResponse(userInput)
            }) {
                Text("SUBMIT")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .disabled(userInput.isEmpty)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(20)
    }
}

// Preview provider for SwiftUI canvas
struct TextInputMessageView_Previews: PreviewProvider {
    static var previews: some View {
        TextInputMessageView(
            message: Message(
                id: "1",
                anchorId: "anchor1",
                type: .textInput,
                title: "How likely are you to recommend Ground Hopper to a friend?",
                content: "Please provide your feedback below",
                options: nil
            ),
            onResponse: { _ in }
        )
    }
}
