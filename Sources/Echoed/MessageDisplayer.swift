import SwiftUI

class MessageDisplayer {
    static let shared = MessageDisplayer()
    private var window: UIWindow?
    
    func display(_ message: Message, completion: @escaping (String) -> Void) {
        DispatchQueue.main.async { [weak self] in
            let view: AnyView
            switch message.type {
            case .multiChoice:
                view = AnyView(MultiChoiceMessageView(message: message, options: message.options ?? [], onResponse: completion, onDismiss: { self?.dismiss() }))
            case .textInput:
                view = AnyView(TextInputMessageView(message: message, onResponse: completion, onDismiss: { self?.dismiss() }))
            }
            
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = .clear
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self?.window = UIWindow(windowScene: scene)
                self?.window?.rootViewController = hostingController
                self?.window?.windowLevel = UIWindow.Level.alert + 1
                self?.window?.backgroundColor = .clear
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

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var userInput: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Text(message.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
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
                onDismiss()
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
        .padding(20)
        .frame(maxWidth: 350)
    }
}

struct MultiChoiceMessageView: View {
    let message: Message
    let options: [String]
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var selectedOption: String?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Text(message.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            
            Button(action: {
                if let selectedOption = selectedOption {
                    onResponse(selectedOption)
                }
                onDismiss()
            }) {
                Text("SUBMIT")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
            }
            .disabled(selectedOption == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .padding(20)
        .frame(maxWidth: 350)
    }
}

// Preview providers
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
            onResponse: { _ in },
            onDismiss: {}
        )
    }
}

struct MultiChoiceMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MultiChoiceMessageView(
            message: Message(
                id: "2",
                anchorId: "anchor2",
                type: .multiChoice,
                title: "How was your experience?",
                content: "Please select one option",
                options: ["Excellent", "Good", "Average", "Poor"]
            ),
            options: ["Excellent", "Good", "Average", "Poor"],
            onResponse: { _ in },
            onDismiss: {}
        )
    }
}
