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

            let isBannerType = message.type == .yesNo || message.type == .thumbsUpDown
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

            // Wrap in animated container — must capture inner view before reassigning
            let innerView = view
            if isBannerType {
                let dismissAction = { self.dismiss() }
                view = AnyView(
                    BannerContainer(onDismiss: dismissAction) { innerView }
                )
            } else {
                view = AnyView(
                    ModalContainer { innerView }
                )
            }

            let hostingController = UIHostingController(rootView: view)
            hostingController.view.backgroundColor = UIColor.clear

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                self.window = UIWindow(windowScene: scene)
                self.window?.rootViewController = hostingController
                self.window?.windowLevel = UIWindow.Level.alert + 1
                self.window?.backgroundColor = .clear
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

// MARK: - Animated Containers

/// Wraps modal views (textInput, multiChoice) with a fade-in backdrop and scale animation.
struct ModalContainer<Content: View>: View {
    let content: () -> Content
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()

            content()
                .scaleEffect(isPresented ? 1 : 0.9)
                .opacity(isPresented ? 1 : 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            }
        }
    }
}

/// Wraps banner views (yesNo, thumbsUpDown) with slide-down animation, tap-to-dismiss, and swipe-up-to-dismiss.
struct BannerContainer<Content: View>: View {
    let onDismiss: () -> Void
    let content: () -> Content
    @State private var isPresented = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack {
                content()
                    .padding(.top, 8)
                    .offset(y: (isPresented ? 0 : -120) + min(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                            }
                            .onEnded { value in
                                if value.translation.height < -40 {
                                    onDismiss()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                Spacer()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Shared Components

/// Brief thank-you shown after submitting feedback in modal views.
struct ThankYouView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var checkScale: CGFloat = 0.2
    @State private var checkOpacity: CGFloat = 0
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .scaleEffect(checkScale)
                .opacity(checkOpacity)
            Text("Thanks!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .opacity(textOpacity)
        }
        .onAppear {
            // Checkmark pops in with a bouncy spring
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                checkScale = 1.0
                checkOpacity = 1.0
            }
            // Text fades in slightly after
            withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

/// Press-scale effect for buttons.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modal Views

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var userInput: String = ""
    @State private var submitted = false
    @Environment(\.colorScheme) var colorScheme

    private var isFormValid: Bool { !userInput.isEmpty }

    var body: some View {
        VStack(spacing: 20) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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

                Button(action: submit) {
                    Text("SUBMIT")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
                .scaleEffect(isFormValid ? 1.0 : 0.97)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: submitted)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 24)
        .frame(maxWidth: 380)
    }

    private func submit() {
        onResponse(userInput)
        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onDismiss()
        }
    }
}

struct MultiChoiceMessageView: View {
    let message: Message
    let options: [String]
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var selectedOption: String?
    @State private var submitted = false
    @Environment(\.colorScheme) var colorScheme

    private var isFormValid: Bool { selectedOption != nil }

    var body: some View {
        VStack(spacing: 20) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedOption = option
                            }
                        }) {
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
                .fixedSize(horizontal: false, vertical: true)

                Button(action: submit) {
                    Text("SUBMIT")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
                .scaleEffect(isFormValid ? 1.0 : 0.97)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: submitted)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(20)
        .padding(.horizontal, 24)
        .frame(maxWidth: 380)
    }

    private func submit() {
        guard let selectedOption = selectedOption else { return }
        onResponse(selectedOption)
        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onDismiss()
        }
    }
}

// MARK: - Banner Views

struct YesNoMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var tapped: String?

    var body: some View {
        HStack(spacing: tapped != nil ? 12 : 16) {
            // Title morphs to "Thanks!" on response
            ZStack(alignment: .leading) {
                Text(message.title)
                    .opacity(tapped == nil ? 1 : 0)
                Text("Thanks!")
                    .fontWeight(.semibold)
                    .opacity(tapped != nil ? 1 : 0)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .lineLimit(2)

            Spacer()

            // Non-selected icon collapses, selected icon fills and bounces
            bannerIcon("xmark", filled: "xmark.circle.fill", response: "no")

            bannerIcon("checkmark", filled: "checkmark.circle.fill", response: "yes")
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func bannerIcon(_ icon: String, filled: String, response: String) -> some View {
        let isSelected = tapped == response
        let isOther = tapped != nil && tapped != response

        return Button(action: { respond(response) }) {
            Image(systemName: isSelected ? filled : icon)
                .font(.system(size: isSelected ? 26 : 22, weight: .medium))
                .foregroundColor(isSelected ? .green : (colorScheme == .dark ? .white : .black))
                .frame(width: isOther ? 0 : 40, height: 40)
                .opacity(isOther ? 0 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(tapped != nil)
    }

    private func respond(_ value: String) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onResponse(value)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            tapped = value
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onDismiss()
        }
    }
}

struct ThumbsUpDownMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var tapped: String?

    var body: some View {
        HStack(spacing: tapped != nil ? 12 : 16) {
            ZStack(alignment: .leading) {
                Text(message.title)
                    .opacity(tapped == nil ? 1 : 0)
                Text("Thanks!")
                    .fontWeight(.semibold)
                    .opacity(tapped != nil ? 1 : 0)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .lineLimit(2)

            Spacer()

            bannerIcon("hand.thumbsdown", filled: "hand.thumbsdown.fill", response: "thumbsDown")

            bannerIcon("hand.thumbsup", filled: "hand.thumbsup.fill", response: "thumbsUp")
        }
        .padding(16)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func bannerIcon(_ icon: String, filled: String, response: String) -> some View {
        let isSelected = tapped == response
        let isOther = tapped != nil && tapped != response

        return Button(action: { respond(response) }) {
            Image(systemName: isSelected ? filled : icon)
                .font(.system(size: isSelected ? 26 : 22, weight: .medium))
                .foregroundColor(isSelected ? .green : (colorScheme == .dark ? .white : .black))
                .frame(width: isOther ? 0 : 40, height: 40)
                .opacity(isOther ? 0 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(tapped != nil)
    }

    private func respond(_ value: String) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onResponse(value)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
            tapped = value
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onDismiss()
        }
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
