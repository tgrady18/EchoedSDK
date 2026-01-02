# Echoed iOS SDK

Collect feedback from your iOS users at key moments in their journey.

## Overview

The Echoed iOS SDK allows you to:
- Display contextual feedback prompts to users
- Collect responses and send them to your Echoed dashboard
- Track user engagement with your messages
- Analyze feedback patterns over time

## Requirements

- iOS 13.0+
- Swift 5.3+
- Xcode 12.0+

## Installation

### Swift Package Manager (Recommended)

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL:
   ```
   https://github.com/your-org/EchoedSDK.git
   ```
3. Select the version you want to use
4. Click **Add Package**

### Manual Installation

1. Download the latest release
2. Drag `Echoed.xcframework` into your Xcode project
3. Ensure "Copy items if needed" is checked
4. Add to your target's "Frameworks, Libraries, and Embedded Content"

## Quick Start

### 1. Initialize the SDK

In your `AppDelegate.swift` or App struct:

```swift
import Echoed

@main
struct YourApp: App {
    init() {
        // Initialize Echoed with your credentials
        EchoedSDK.shared.initialize(
            apiKey: "YOUR_API_KEY",
            companyId: "YOUR_COMPANY_ID"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Find your credentials:**
1. Log in to your Echoed dashboard
2. Go to Settings
3. Copy your API Key and Company ID

### 2. Display Messages

Show messages at key moments in your app:

```swift
import Echoed
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack {
            // Your onboarding content
            Text("Welcome!")
        }
        .onAppear {
            // Show message when onboarding completes
            EchoedSDK.shared.hitAnchor("onboarding_complete")
        }
    }
}
```

### 3. Set User Tags (Optional)

Add context about your users with tags:

```swift
// After user logs in
EchoedSDK.shared.setUserTag("email", value: "user@example.com", type: .string)
EchoedSDK.shared.setUserTag("plan", value: "premium", type: .string)
EchoedSDK.shared.setUserTag("signupDate", value: "2024-01-15", type: .string)
```

## Core Concepts

### Anchors

**Anchors** are specific locations in your app where messages can be displayed. Examples:
- `onboarding_complete` - After user finishes onboarding
- `first_purchase` - After user's first purchase
- `feature_discovery` - When user discovers a new feature
- `checkout_abandoned` - When user abandons checkout

### Messages

Messages are created in the Echoed dashboard and linked to anchors. They can be:
- **Text prompts** - Simple text questions
- **Rating requests** - Star ratings or numeric scales
- **Multiple choice** - Predefined options
- **Open-ended** - Free-form text responses

### Display Rules

Control when and how often messages are shown:
- **Frequency** - Once per session, daily, weekly, etc.
- **User segments** - Target specific user groups
- **A/B testing** - Test different message variations

## Common Use Cases

### Example 1: Post-Purchase Feedback

```swift
struct CheckoutSuccessView: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Order Confirmed!")
        }
        .onAppear {
            // Ask about purchase experience
            Echoed.showMessage(anchorId: "purchase_complete")
        }
    }
}
```

### Example 2: Feature Feedback

```swift
struct NewFeatureView: View {
    @State private var featureUsed = false

    var body: some View {
        VStack {
            // Your new feature UI
        }
        .onChange(of: featureUsed) { used in
            if used {
                // After user tries the feature
                Echoed.showMessage(anchorId: "new_feature_used")
            }
        }
    }
}
```

### Example 3: App Rating

```swift
struct MainView: View {
    @AppStorage("appLaunchCount") var launchCount = 0

    var body: some View {
        ContentView()
            .onAppear {
                launchCount += 1

                // Ask for rating after 10 launches
                if launchCount == 10 {
                    Echoed.showMessage(anchorId: "app_rating_request")
                }
            }
    }
}
```

## Advanced Usage

### Custom Message Display

Customize how messages appear in your app:

```swift
Echoed.configure { config in
    config.messagePosition = .bottom
    config.animationDuration = 0.3
    config.backgroundColor = .black
    config.textColor = .white
}
```

### Handling Message Responses

Get notified when users respond:

```swift
Echoed.onMessageResponse { response in
    print("User responded: \(response.message)")

    // Track in your analytics
    Analytics.track("feedback_submitted", properties: [
        "message_id": response.messageId,
        "response_length": response.message.count
    ])
}
```

### Offline Support

The SDK automatically queues messages and responses when offline:

```swift
// Responses are automatically synced when connection returns
Echoed.showMessage(anchorId: "offline_test")
// Response will be sent once online
```

## API Reference

### Initialization

```swift
Echoed.initialize(companyId: String)
```

### Display Messages

```swift
// Show message at anchor point
Echoed.showMessage(anchorId: String)

// Show with additional context
Echoed.showMessage(anchorId: String, context: [String: Any])
```

### User Identification

```swift
// Identify user
Echoed.identify(userId: String, properties: [String: Any])

// Clear user identity (on logout)
Echoed.clearIdentity()
```

### Event Tracking

```swift
// Track custom event
Echoed.track(event: String, properties: [String: Any])
```

### Configuration

```swift
Echoed.configure { config in
    config.debugMode = true
    config.messagePosition = .bottom
    config.autoTrackScreenViews = true
}
```

## Testing

### Test Mode

Enable test mode to see all messages regardless of display rules:

```swift
#if DEBUG
Echoed.configure { config in
    config.debugMode = true
}
#endif
```

### Preview Messages

Preview messages before deploying:

```swift
// In your dashboard, create a test message
// Set it to only show for test users

#if DEBUG
Echoed.identify(userId: "test_user", properties: [
    "is_tester": true
])
#endif
```

## Troubleshooting

### Messages Not Showing

1. **Check Company ID**: Verify your company ID is correct
2. **Check Anchor ID**: Ensure the anchor ID matches what's in your dashboard
3. **Check Display Rules**: Verify the message's display rules allow it to show
4. **Check Debug Logs**: Enable debug mode to see detailed logs

```swift
Echoed.configure { config in
    config.debugMode = true
}
```

### Responses Not Saving

1. **Check Network**: Verify the device has internet connectivity
2. **Check Firebase**: Ensure Firebase is properly configured
3. **Check Logs**: Look for error messages in the console

### Build Issues

**Swift Package Manager:**
- Update packages: **File > Packages > Update to Latest Package Versions**
- Reset package cache: **File > Packages > Reset Package Caches**

**Manual Installation:**
- Verify framework is added to "Frameworks, Libraries, and Embedded Content"
- Check "Embed & Sign" is selected

## Best Practices

### Do's ✅

- Show messages at natural moments in the user journey
- Keep message frequency reasonable (not too annoying)
- Use clear, concise language in your prompts
- Test messages thoroughly before deploying
- Monitor response rates in your dashboard

### Don'ts ❌

- Don't show messages immediately on app launch
- Don't interrupt critical user flows
- Don't ask the same question repeatedly
- Don't use technical jargon in messages
- Don't ignore user feedback

## Privacy & Security

- User data is encrypted in transit and at rest
- No personal information is collected without explicit user action
- Users can opt out of feedback collection
- GDPR and CCPA compliant

## Support

- **Documentation**: [docs.echoed.app](https://docs.echoed.app)
- **Email**: support@echoed.app
- **GitHub Issues**: [github.com/your-org/EchoedSDK/issues](https://github.com/your-org/EchoedSDK/issues)

## License

Proprietary - All rights reserved

## Changelog

### v1.0.0 (Current)
- Initial release
- Message display
- Response collection
- User identification
- Event tracking
- Offline support
