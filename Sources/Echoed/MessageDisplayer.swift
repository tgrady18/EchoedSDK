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

/// Wraps modal views with a fade-in backdrop and scale animation.
struct ModalContainer<Content: View>: View {
    let content: () -> Content
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Color.black.opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()

            content()
                .scaleEffect(isPresented ? 1 : 0.92)
                .opacity(isPresented ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.4), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            }
        }
    }
}

/// Wraps banner views with slide-down, swipe-to-dismiss, and tap-outside-to-dismiss.
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
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
        }
    }
}

// MARK: - Shared Components

/// Confirmation shown after submitting feedback in modal views.
struct ThankYouView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var checkScale: CGFloat = 0.0
    @State private var checkOpacity: CGFloat = 0
    @State private var textOffset: CGFloat = 8
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundColor(.green)
                .scaleEffect(checkScale)
                .opacity(checkOpacity)
            Text("Thank you")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                .offset(y: textOffset)
                .opacity(textOpacity)
        }
        .onAppear {
            // Checkmark: deliberate spring with visible bounce
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.1)) {
                checkScale = 1.0
                checkOpacity = 1.0
            }
            // Text slides up and fades in after checkmark lands
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                textOffset = 0
                textOpacity = 1.0
            }
            // Success haptic timed to checkmark landing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

/// Subtle press-scale for interactive elements.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Modal Views

struct TextInputMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @State private var userInput: String = ""
    @State private var submitted = false
    @State private var dismissing = false
    @Environment(\.colorScheme) var colorScheme

    private var isFormValid: Bool { !userInput.isEmpty }

    var body: some View {
        VStack(spacing: 20) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
            } else {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }

                Text(message.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                TextField("Your thoughts...", text: $userInput)
                    .padding(14)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)

                Button(action: submit) {
                    Text("Submit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.4)
                .scaleEffect(isFormValid ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.3), value: isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: submitted)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 0.95 : 1.0)
        .animation(.easeIn(duration: 0.25), value: dismissing)
        .padding(.horizontal, 24)
        .frame(maxWidth: 380)
    }

    private func submit() {
        onResponse(userInput)
        withAnimation { submitted = true }
        // Hold for the thank-you to breathe, then gracefully exit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { dismissing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
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
    @State private var dismissing = false
    @Environment(\.colorScheme) var colorScheme

    private var isFormValid: Bool { selectedOption != nil }

    var body: some View {
        VStack(spacing: 20) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 44)
            } else {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }

                Text(message.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedOption = option
                            }
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: selectedOption == option ? "circle.inset.filled" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedOption == option ?
                                        (colorScheme == .dark ? .white : .black) :
                                        Color(UIColor.systemGray3))
                                Text(option)
                                    .font(.system(size: 16))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Button(action: submit) {
                    Text("Submit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.4)
                .scaleEffect(isFormValid ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.3), value: isFormValid)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: submitted)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 0.95 : 1.0)
        .animation(.easeIn(duration: 0.25), value: dismissing)
        .padding(.horizontal, 24)
        .frame(maxWidth: 380)
    }

    private func submit() {
        guard let selectedOption = selectedOption else { return }
        onResponse(selectedOption)
        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { dismissing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
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
    @State private var slideOut = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .leading) {
                Text(message.title)
                    .opacity(tapped == nil ? 1 : 0)
                Text("Thank you")
                    .opacity(tapped != nil ? 1 : 0)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .lineLimit(2)

            Spacer(minLength: 8)

            bannerIcon("xmark", filled: "xmark.circle.fill", response: "no")
            bannerIcon("checkmark", filled: "checkmark.circle.fill", response: "yes")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .offset(y: slideOut ? -100 : 0)
        .opacity(slideOut ? 0 : 1)
        .animation(.easeIn(duration: 0.3), value: slideOut)
    }

    private func bannerIcon(_ icon: String, filled: String, response: String) -> some View {
        let isSelected = tapped == response
        let isOther = tapped != nil && tapped != response

        return Button(action: { respond(response) }) {
            Image(systemName: isSelected ? filled : icon)
                .font(.system(size: isSelected ? 28 : 22, weight: .medium))
                .foregroundColor(isSelected ? .green : (colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)))
                .frame(width: isOther ? 0 : 44, height: 44)
                .opacity(isOther ? 0 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(tapped != nil)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: tapped)
    }

    private func respond(_ value: String) {
        onResponse(value)
        // 1: Icon fills + shifts
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            tapped = value
        }
        // 2: Success haptic timed to the icon settling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        // 3: Hold, then slide up and away
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            slideOut = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onDismiss()
            }
        }
    }
}

struct ThumbsUpDownMessageView: View {
    let message: Message
    let onResponse: (String) -> Void
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var tapped: String?
    @State private var slideOut = false

    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .leading) {
                Text(message.title)
                    .opacity(tapped == nil ? 1 : 0)
                Text("Thank you")
                    .opacity(tapped != nil ? 1 : 0)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .lineLimit(2)

            Spacer(minLength: 8)

            bannerIcon("hand.thumbsdown", filled: "hand.thumbsdown.fill", response: "thumbsDown")
            bannerIcon("hand.thumbsup", filled: "hand.thumbsup.fill", response: "thumbsUp")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
        .offset(y: slideOut ? -100 : 0)
        .opacity(slideOut ? 0 : 1)
        .animation(.easeIn(duration: 0.3), value: slideOut)
    }

    private func bannerIcon(_ icon: String, filled: String, response: String) -> some View {
        let isSelected = tapped == response
        let isOther = tapped != nil && tapped != response

        return Button(action: { respond(response) }) {
            Image(systemName: isSelected ? filled : icon)
                .font(.system(size: isSelected ? 28 : 22, weight: .medium))
                .foregroundColor(isSelected ? .green : (colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)))
                .frame(width: isOther ? 0 : 44, height: 44)
                .opacity(isOther ? 0 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(tapped != nil)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: tapped)
    }

    private func respond(_ value: String) {
        onResponse(value)
        // 1: Icon fills + shifts
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            tapped = value
        }
        // 2: Success haptic timed to the icon settling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        // 3: Hold, then slide up and away
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            slideOut = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onDismiss()
            }
        }
    }
}

// MARK: - Previews

struct TextInputMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.gray.ignoresSafeArea()
                TextInputMessageView(
                    message: Message(id: "1", anchorId: "a", type: .textInput,
                        title: "How's your experience so far?",
                        content: "We'd love to hear your thoughts",
                        options: nil),
                    onResponse: { _ in }, onDismiss: {}
                )
            }
            .previewDisplayName("Light")
            .preferredColorScheme(.light)

            ZStack {
                Color.black.ignoresSafeArea()
                TextInputMessageView(
                    message: Message(id: "1", anchorId: "a", type: .textInput,
                        title: "How's your experience so far?",
                        content: "We'd love to hear your thoughts",
                        options: nil),
                    onResponse: { _ in }, onDismiss: {}
                )
            }
            .previewDisplayName("Dark")
            .preferredColorScheme(.dark)
        }
    }
}

struct MultiChoiceMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.gray.ignoresSafeArea()
                MultiChoiceMessageView(
                    message: Message(id: "2", anchorId: "a", type: .multiChoice,
                        title: "How was your experience?",
                        content: "", options: ["Great", "Good", "Okay", "Not great"]),
                    options: ["Great", "Good", "Okay", "Not great"],
                    onResponse: { _ in }, onDismiss: {}
                )
            }
            .previewDisplayName("Light")
            .preferredColorScheme(.light)
        }
    }
}

struct YesNoMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack { YesNoMessageView(
                message: Message(id: "3", anchorId: "a", type: .yesNo,
                    title: "Was this helpful?", content: "", options: nil),
                onResponse: { _ in }, onDismiss: {}
            ); Spacer() }
            .previewDisplayName("Light")
            .preferredColorScheme(.light)
        }
    }
}

struct ThumbsUpDownMessageView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack { ThumbsUpDownMessageView(
                message: Message(id: "4", anchorId: "a", type: .thumbsUpDown,
                    title: "Did you enjoy this feature?", content: "", options: nil),
                onResponse: { _ in }, onDismiss: {}
            ); Spacer() }
            .previewDisplayName("Light")
            .preferredColorScheme(.light)
        }
    }
}
