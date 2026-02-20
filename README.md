# Echoed iOS SDK

Drop-in user feedback for iOS — show contextual prompts at key moments and collect responses to your [Echoed dashboard](https://echoed-feedback.com).

## Requirements

- iOS 13.0+
- Swift 5.3+
- Xcode 12.0+

## Installation

Add via Swift Package Manager:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL:
   ```
   https://github.com/tgrady18/EchoedSDK.git
   ```
3. Select your version and click **Add Package**

## Quick Start

### 1. Initialize

In your App struct or `AppDelegate`:

```swift
import Echoed

@main
struct YourApp: App {
    init() {
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

Find your API Key and Company ID in [Settings](https://echoed-feedback.com/companyConfig).

### 2. Hit an Anchor

Anchors are trigger points in your app where feedback can appear. Call `hitAnchor` and the SDK handles the rest — it checks the backend for any messages configured for that anchor, and displays them if found.

```swift
struct CheckoutSuccessView: View {
    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Order Confirmed!")
        }
        .onAppear {
            EchoedSDK.shared.hitAnchor("post_purchase")
        }
    }
}
```

Anchor IDs (e.g. `"post_purchase"`) are strings you define — they must match what you've configured in [Messages](https://echoed-feedback.com/messages). If no message is configured for an anchor, nothing is displayed.

### 3. Set User Tags (Optional)

Tags attach metadata to the current user for targeting rules. The `type` parameter tells the SDK how to validate and store the value.

```swift
EchoedSDK.shared.setUserTag("plan", value: "pro", type: .string)
EchoedSDK.shared.setUserTag("purchase_count", value: 5, type: .number)
EchoedSDK.shared.setUserTag("is_beta", value: true, type: .boolean)
EchoedSDK.shared.setUserTag("subscribed_at", value: Date(), type: .timestamp)
```

Tags are persisted locally (UserDefaults) and synced to the backend automatically.

## Core Concepts

### Anchors

An **anchor** is a named trigger point in your app. When you call `hitAnchor`, the SDK:

1. Records the hit to the backend
2. Fetches any messages linked to that anchor (filtered by user tags and targeting rules)
3. Displays matched messages as a modal overlay

You create anchors and link messages to them in the [Messages](https://echoed-feedback.com/messages) page.

### Messages

Messages are [created in the dashboard](https://echoed-feedback.com/messages/create) and displayed by the SDK. Two types are supported:

| Type | What the user sees |
|---|---|
| **Text Input** | A prompt with a title, description, free-form text field, and submit button |
| **Multiple Choice** | A prompt with a title, description, scrollable option picker, and submit button |

Messages appear as a centered modal with a semi-transparent backdrop. The UI adapts to light/dark mode automatically. Users can dismiss via the X button or submit a response.

Responses are sent to the backend automatically — no callback is needed on the developer side.

### User Tags

Tags are key-value pairs attached to the user. They serve two purposes:

- **Targeting** — The dashboard uses tag conditions to control which users see which messages
- **Context** — Tags are included with responses so you can segment feedback

Available tag types:

| TagType | Swift types accepted | Example |
|---|---|---|
| `.string` | `String` | `"premium"` |
| `.number` | `Int`, `Double` | `42`, `3.14` |
| `.boolean` | `Bool` | `true` |
| `.timestamp` | `Date`, `TimeInterval` | `Date()`, `1700000000.0` |

### Automatic Tags

The SDK tracks these tags internally. They're set automatically and **cannot be removed**:

| Tag | Type | Description |
|---|---|---|
| `first_session_time` | `.timestamp` | When the SDK was first initialized on this device |
| `session_count` | `.number` | Number of app sessions (incremented when the app returns to foreground after 5+ seconds in background) |
| `last_session_time` | `.timestamp` | Timestamp of the most recent session |

These appear alongside your custom tags in `getAllUserTags()` and are sent with network requests.

### Device ID

The SDK generates and persists a unique device identifier (UUID) in UserDefaults. This ID is sent with message fetch and display requests for tracking.

```swift
let deviceId = EchoedSDK.shared.deviceManager.getDeviceId()
```

The device ID resets if the app is uninstalled and reinstalled.

## API Reference

### Initialization

```swift
EchoedSDK.shared.initialize(apiKey: String, companyId: String)
```

Call once at app launch before using any other SDK methods.

### Anchors

```swift
// Trigger an anchor — fetches and displays any matching messages
EchoedSDK.shared.hitAnchor(_ anchorId: String)
```

### User Tags

```swift
// Set a tag (creates or overwrites)
EchoedSDK.shared.setUserTag(_ key: String, value: Any, type: UserTagManager.TagType)

// Read tags
EchoedSDK.shared.getUserTagValue(_ key: String) -> Any?
EchoedSDK.shared.getUserTagType(_ key: String) -> UserTagManager.TagType?
EchoedSDK.shared.getAllUserTags() -> [String: Any]

// Remove a single custom tag (internal tags cannot be removed)
EchoedSDK.shared.removeUserTag(_ key: String)

// Remove all custom tags (internal tags are preserved)
EchoedSDK.shared.clearAllUserTags()
```

### Device

```swift
// Get the persistent device UUID
EchoedSDK.shared.deviceManager.getDeviceId() -> String
```

### Debug

```swift
// Print all tags (custom + internal) to the console
EchoedSDK.shared.printAllTags()
```

## Troubleshooting

### Messages not showing

1. **Verify credentials** — Confirm your `apiKey` and `companyId` are correct
2. **Check the anchor ID** — The string passed to `hitAnchor` must exactly match what's configured in the dashboard
3. **Check targeting rules** — Your user's tags may not satisfy the message's conditions
4. **Check the console** — The SDK prints errors for network failures and missing configuration
5. **Confirm a UIWindowScene is available** — The SDK needs an active window scene to present the overlay. Don't call `hitAnchor` before the app's UI has loaded.

### Responses not saving

1. **Check network connectivity** — Responses are sent immediately on submit; there is no offline queue
2. **Check console output** — Look for "Error sending response" messages

### Build issues

- **Update packages**: File > Packages > Update to Latest Package Versions
- **Reset cache**: File > Packages > Reset Package Caches

## Dashboard

This SDK is the client-side half of Echoed. All message creation, anchor configuration, targeting rules, and response analytics live in the web dashboard at [echoed-feedback.com](https://echoed-feedback.com).

From the dashboard you can:
- [Create and edit feedback messages](https://echoed-feedback.com/messages/create) (text input or multiple choice)
- [Manage messages](https://echoed-feedback.com/messages) and link them to anchor IDs
- [View collected responses](https://echoed-feedback.com/responses) and analyze feedback
- [Browse insights](https://echoed-feedback.com/insights) generated from response data
- Find your API Key and Company ID in [Settings](https://echoed-feedback.com/companyConfig)

## License

Proprietary - All rights reserved
