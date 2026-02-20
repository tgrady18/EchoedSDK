# Echoed iOS SDK

## What This Is

iOS SDK (Swift Package) for the Echoed feedback platform. Displays contextual feedback prompts (text input, multiple choice, yes/no, thumbs up/down) at anchor points in a host app. Responses are sent to a Firebase Cloud Functions backend. The companion admin dashboard lives at https://github.com/tgrady18/echoed-admin.

## Build

This is an **iOS-only** target (iOS 13+). It cannot be built with `swift build` on macOS — UIKit/SwiftUI are not available for macOS targets. Build with Xcode:

```
xcodebuild -scheme Echoed -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or open in Xcode and build for any iOS simulator/device target.

## Project Structure

```
Sources/Echoed/
  EchoedSDK.swift        — Public API singleton (EchoedSDK.shared)
  Models.swift           — Message, MessageType enum, TagCondition, RuleSet, AnyCodable
  MessageDisplayer.swift — SwiftUI views for all message types + UIWindow overlay display
  MessageManager.swift   — Message queue, presents sequentially, sends responses
  NetworkManager.swift   — Firebase Cloud Functions HTTP client
  UserTagManager.swift   — User tag storage (UserDefaults), session tracking
  AnchorManager.swift    — Local anchor hit tracking
  DeviceManager.swift    — Persistent device UUID
```

## Key Architecture

- **Public API**: Everything goes through `EchoedSDK.shared` — `initialize()`, `hitAnchor()`, `setUserTag()`, etc.
- **Message types**: `textInput`, `multiChoice`, `yesNo`, `thumbsUpDown` (enum `MessageType` in Models.swift)
- **Display**: Messages render via a UIWindow overlay at `alert+1` level. Modal types (textInput, multiChoice) get a semi-transparent backdrop. Banner types (yesNo, thumbsUpDown) get a clear background and pin to the top of the screen.
- **Responses**: All responses are strings. The selected option, typed text, "yes"/"no", "thumbsUp"/"thumbsDown" — all sent as strings via `NetworkManager.sendMessageResponse()`.
- **Dark/light mode**: All views use `@Environment(\.colorScheme)` with manual color switching (`colorScheme == .dark ? .white : .black`).
- **No offline queue**: Responses are sent immediately. If the network call fails, the response is lost.

## Patterns to Follow

- **Adding a new message type**: Add case to `MessageType` enum in Models.swift, create a SwiftUI view in MessageDisplayer.swift, add a switch case in `MessageDisplayer.display()`, add preview providers. The admin dashboard type union in `types/messages.ts` must also be updated.
- **View structure**: Modal views use `VStack(spacing: 20)`, `.frame(maxWidth: 350)`, `.cornerRadius(20)`, `.padding(20)`. Banner views use `HStack(spacing: 16)`, `.cornerRadius(16)`, `.padding(.horizontal, 16)`, shadow.
- **Haptic feedback**: `UIImpactFeedbackGenerator(style: .medium)` on submit/select actions.
- **Tag types**: `.string`, `.number`, `.boolean`, `.timestamp` — validated in UserTagManager.

## Common Pitfalls

- Do not use `swift build` — it will fail with "no such module UIKit". Always build for iOS target.
- The `MessageType` raw values must match exactly between the SDK (Swift) and admin dashboard (TypeScript) and Firestore documents. Adding a type in one place means adding it everywhere.
- The admin dashboard had a bug where the type dropdown used `"text"` instead of `"textInput"` — if you see `"text"` in Firestore data, it's this legacy bug.
- Internal tags (`first_session_time`, `session_count`, `last_session_time`) cannot be removed by users — `removeTag` and `clearAllTags` protect them.

## Related Repo

The admin dashboard (React/TypeScript/Firebase) is at `/Users/trevorgrady/Documents/VS/echoed-admin/`. Key files:
- `react-app/src/types/messages.ts` — MessageType union (must stay in sync with SDK)
- `react-app/src/components/CreateMessage.tsx` — Message creation form
- `functions/index.js` — Cloud Functions (fetchMessagesForAnchor, sendMessageResponse)
