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

/// Glass backdrop with scale entrance for modal views.
struct ModalContainer<Content: View>: View {
    let content: () -> Content
    @State private var isPresented = false

    var body: some View {
        ZStack {
            // Frosted glass backdrop — not a flat black overlay
            Color.clear
                .background(.ultraThinMaterial)
                .opacity(isPresented ? 1 : 0)
                .ignoresSafeArea()

            content()
                .scaleEffect(isPresented ? 1 : 0.88)
                .opacity(isPresented ? 1 : 0)
        }
        .animation(.easeOut(duration: 0.45), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred()
            }
        }
    }
}

/// Slide-down container for banner views with swipe-to-dismiss.
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
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                Spacer()
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: isPresented)
        .onAppear {
            DispatchQueue.main.async { isPresented = true }
        }
    }
}

// MARK: - Shared Components

/// Confirmation moment after submitting feedback.
struct ThankYouView: View {
    @State private var checkScale: CGFloat = 0.0
    @State private var checkOpacity: CGFloat = 0
    @State private var glowScale: CGFloat = 0.5
    @State private var glowOpacity: CGFloat = 0
    @State private var textOffset: CGFloat = 12
    @State private var textOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Soft green glow behind the checkmark
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .scaleEffect(glowScale)
                    .opacity(glowOpacity)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.green)
                    .scaleEffect(checkScale)
                    .opacity(checkOpacity)
            }

            Text("Thank you")
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundColor(.secondary)
                .offset(y: textOffset)
                .opacity(textOpacity)
        }
        .onAppear {
            // Glow expands first
            withAnimation(.easeOut(duration: 0.5).delay(0.05)) {
                glowScale = 1.0
                glowOpacity = 1.0
            }
            // Checkmark bounces in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.1)) {
                checkScale = 1.0
                checkOpacity = 1.0
            }
            // Text slides up after checkmark settles
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                textOffset = 0
                textOpacity = 1.0
            }
            // Haptic timed to checkmark landing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

/// Press-scale for buttons.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
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
        VStack(spacing: 0) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 16)

                // Title
                Text(message.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                // Subtitle
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 6)
                }

                // Text field
                TextField("Share your thoughts...", text: $userInput)
                    .font(.system(.body, design: .rounded))
                    .padding(14)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                // Submit
                Button(action: submit) {
                    Text("Submit")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.35)
                .scaleEffect(isFormValid ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.35), value: isFormValid)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: submitted)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white)
                .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 10)
        )
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 0.92 : 1.0)
        .animation(.easeIn(duration: 0.3), value: dismissing)
        .padding(.horizontal, 20)
        .frame(maxWidth: 400)
    }

    private func submit() {
        onResponse(userInput)
        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { dismissing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
        VStack(spacing: 0) {
            if submitted {
                ThankYouView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 16)

                Text(message.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 6)
                }

                // Options
                VStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedOption = option
                            }
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: selectedOption == option ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(selectedOption == option ? .green : Color(UIColor.systemGray3))
                                Text(option)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedOption == option ?
                                        Color.green.opacity(0.08) :
                                        Color(UIColor.tertiarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(selectedOption == option ?
                                        Color.green.opacity(0.3) : .clear, lineWidth: 1.5)
                            )
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Button(action: submit) {
                    Text("Submit")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(colorScheme == .dark ? Color.white : Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.35)
                .scaleEffect(isFormValid ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.35), value: isFormValid)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: submitted)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white)
                .shadow(color: .black.opacity(0.06), radius: 24, x: 0, y: 10)
        )
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 0.92 : 1.0)
        .animation(.easeIn(duration: 0.3), value: dismissing)
        .padding(.horizontal, 20)
        .frame(maxWidth: 400)
    }

    private func submit() {
        guard let selectedOption = selectedOption else { return }
        onResponse(selectedOption)
        withAnimation { submitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { dismissing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(2)

            Spacer(minLength: 8)

            bannerIcon("xmark", filled: "xmark.circle.fill", response: "no")
            bannerIcon("checkmark", filled: "checkmark.circle.fill", response: "yes")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
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
                .font(.system(size: isSelected ? 28 : 20, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(isSelected ? .green : .primary.opacity(0.6))
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            tapped = value
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
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
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(2)

            Spacer(minLength: 8)

            bannerIcon("hand.thumbsdown", filled: "hand.thumbsdown.fill", response: "thumbsDown")
            bannerIcon("hand.thumbsup", filled: "hand.thumbsup.fill", response: "thumbsUp")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
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
                .font(.system(size: isSelected ? 28 : 20, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(isSelected ? .green : .primary.opacity(0.6))
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            tapped = value
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
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
        ZStack {
            Color.blue.opacity(0.3).ignoresSafeArea()
            TextInputMessageView(
                message: Message(id: "1", anchorId: "a", type: .textInput,
                    title: "How's your experience?",
                    content: "We'd love your feedback", options: nil),
                onResponse: { _ in }, onDismiss: {}
            )
        }
    }
}

struct MultiChoiceMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.opacity(0.3).ignoresSafeArea()
            MultiChoiceMessageView(
                message: Message(id: "2", anchorId: "a", type: .multiChoice,
                    title: "How was your experience?",
                    content: "", options: ["Great", "Good", "Okay", "Not great"]),
                options: ["Great", "Good", "Okay", "Not great"],
                onResponse: { _ in }, onDismiss: {}
            )
        }
    }
}

struct BannerMessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            YesNoMessageView(
                message: Message(id: "3", anchorId: "a", type: .yesNo,
                    title: "Was this helpful?", content: "", options: nil),
                onResponse: { _ in }, onDismiss: {}
            )
            ThumbsUpDownMessageView(
                message: Message(id: "4", anchorId: "a", type: .thumbsUpDown,
                    title: "Enjoying this feature?", content: "", options: nil),
                onResponse: { _ in }, onDismiss: {}
            )
            Spacer()
        }
    }
}
