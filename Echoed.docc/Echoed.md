# ``Echoed``

Drop-in user feedback for iOS — show contextual prompts at key moments and collect responses.

## Overview

The Echoed SDK lets you display feedback prompts (text input or multiple choice) at specific points in your app. You define **anchors** as trigger points, configure messages in the Echoed dashboard, and the SDK handles fetching, displaying, and submitting responses.

Initialize the SDK at app launch with your API key and company ID, then call ``EchoedSDK/hitAnchor(_:)`` wherever you want feedback to appear. Use **user tags** to attach metadata for targeting rules.

## Topics

### Essentials

- ``EchoedSDK``

### User Tags

- ``UserTagManager``

### Device

- ``DeviceManager``

### Models

- ``Message``
- ``MessageType``
- ``TagType``
- ``RuleSet``
- ``TagCondition``
