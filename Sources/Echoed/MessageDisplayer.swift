import SwiftUI

class MessageDisplayer {
    static let shared = MessageDisplayer()
    private var window: UIWindow?
    
    func display(_ message: Message, completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            EchoedSDK.shared.networkManager.recordMessageDisplay(messageId: message.id) { result in
                           switch result {
                           case .success:
                               print("Display recorded successfully")
                           case .failure(let error):
                               print("Error recording display: \(error)")
                           }
                       }
            let view: AnyView
            switch message.type {
            case .multiChoice:
                view = AnyView(MultiChoiceMessageView(
                    message: message,
                    options: message.options ?? [],
                    onResponse: completion,
                    onDismiss: { self.dismiss() }
                ))
            case .textInput:
                view = AnyView(TextInputMessageView(
                    message: message,
                    onResponse: completion,
                    onDismiss: { self.dismiss() }
                ))
            }
            
            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = UIColor.clear // Ensure transparency
            
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.window = UIWindow(windowScene: scene)
                self.window?.rootViewController = hostingController
                self.window?.windowLevel = UIWindow.Level.alert + 1
                self.window?.backgroundColor = UIColor.black.withAlphaComponent(0.5) // Semi-transparent background
                self.window?.makeKeyAndVisible()
            } else {
                print("No active UIWindowScene found.")
            }
        }
    }
    
    private func dismiss() {
        DispatchQueue.main.async {
            print("Dismiss called")
            self.window?.isHidden = true
            self.window = nil
        }
    }
}

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var userInput: String = ""
    @Environment(\.colorScheme) var colorScheme
    
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
                .foregroundColor(colorScheme == .dark ? .white : .black) // High contrast
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            TextField("Enter your response", text: $userInput)
                .padding()
                .background(Color(UIColor.systemGray5))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .keyboardType(.default)
                .cornerRadius(10)
                .padding(.horizontal, 20)
            
            Button(action: {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                onResponse(userInput)
                onDismiss()
            }) {
                Text("SUBMIT")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .black : .white) // High contrast
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black) // High contrast
                    .cornerRadius(10)
            }
            .disabled(userInput.isEmpty)
            .opacity(userInput.isEmpty ? 0.5 : 1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(colorScheme == .dark ? Color.black : Color.white) // High contrast background
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
    @Environment(\.colorScheme) var colorScheme
    
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
                .foregroundColor(colorScheme == .dark ? .white : .black) // High contrast
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text(message.content)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Picker("Select an option", selection: $selectedOption) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .tag(option as String?)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .background(Color(UIColor.systemGray5))
            .cornerRadius(10)
            .padding()
            
            Button(action: {
                if let selectedOption = selectedOption {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    onResponse(selectedOption)
                }
                onDismiss()
            }) {
                Text("SUBMIT")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .black : .white) // High contrast
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark ? Color.white : Color.black) // High contrast
                    .cornerRadius(10)
            }
            .disabled(selectedOption == nil)
            .opacity(selectedOption == nil ? 0.5 : 1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(colorScheme == .dark ? Color.black : Color.white) // High contrast background
        .cornerRadius(20)
        .padding(20)
        .frame(maxWidth: 350)
    }
}

// Preview providers
struct TextInputMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
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
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)
            
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
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
    }
}

struct MultiChoiceMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
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
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)
            
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
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
    }
}
