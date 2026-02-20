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
            var view: AnyView
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
            case .yesNo:
                view = AnyView(YesNoMessageView(
                    message: message,
                    onResponse: completion,
                    onDismiss: { self.dismiss() }
                ))
            case .thumbsUpDown:
                view = AnyView(ThumbsUpDownMessageView(
                    message: message,
                    onResponse: completion,
                    onDismiss: { self.dismiss() }
                ))
            }

            let isBannerType = message.type == .yesNo || message.type == .thumbsUpDown

            // For banner types, wrap to pin to top of screen with tap-to-dismiss background
            if isBannerType {
                let dismissAction = { self.dismiss() }
                view = AnyView(
                    ZStack {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { dismissAction() }
                        VStack {
                            view
                                .padding(.top, 60)
                            Spacer()
                        }
                    }
                )
            }

            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = UIColor.clear // Ensure transparency

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.window = UIWindow(windowScene: scene)
                self.window?.rootViewController = hostingController
                self.window?.windowLevel = UIWindow.Level.alert + 1
                self.window?.backgroundColor = isBannerType ? UIColor.clear : UIColor.black.withAlphaComponent(0.5)
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
            
            VStack(spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button(action: { selectedOption = option }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedOption == option ? "circle.inset.filled" : "circle")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Text(option)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                }
            }
            
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

struct YesNoMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Text(message.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(2)

            Spacer()

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onResponse("no")
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onResponse("yes")
                onDismiss()
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

struct ThumbsUpDownMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Text(message.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(2)

            Spacer()

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onResponse("thumbsDown")
                onDismiss()
            }) {
                Image(systemName: "hand.thumbsdown")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onResponse("thumbsUp")
                onDismiss()
            }) {
                Image(systemName: "hand.thumbsup")
                    .font(.system(size: 24))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
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

struct YesNoMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            YesNoMessageView(
                message: Message(
                    id: "3",
                    anchorId: "anchor3",
                    type: .yesNo,
                    title: "Was this tip useful?",
                    content: "",
                    options: nil
                ),
                onResponse: { _ in },
                onDismiss: {}
            )
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)

            YesNoMessageView(
                message: Message(
                    id: "3",
                    anchorId: "anchor3",
                    type: .yesNo,
                    title: "Was this tip useful?",
                    content: "",
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

struct ThumbsUpDownMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ThumbsUpDownMessageView(
                message: Message(
                    id: "4",
                    anchorId: "anchor4",
                    type: .thumbsUpDown,
                    title: "Did you find this helpful?",
                    content: "",
                    options: nil
                ),
                onResponse: { _ in },
                onDismiss: {}
            )
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)

            ThumbsUpDownMessageView(
                message: Message(
                    id: "4",
                    anchorId: "anchor4",
                    type: .thumbsUpDown,
                    title: "Did you find this helpful?",
                    content: "",
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
