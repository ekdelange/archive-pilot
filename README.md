# ArchivePilot

ArchivePilot is an iOS 18.4+ document filing assistant optimized for the iPhone 16 generation. The app and its Share Extension classify incoming documents, suggest an archive destination within user-selected iCloud Drive folders, and generate compliant file names using Apple Intelligence when available.

## Features

- Share Extension entry point for PDFs, images, and text attachments
- On-device Apple Intelligence classification with heuristics and optional OpenAI fallback
- Security-scoped bookmarks for user-selected iCloud archive roots
- Rule learning when the user adjusts a proposed filing
- SwiftUI application with Settings, Privacy information, and inbox processing

## Targets

- **ArchivePilot** – main SwiftUI app
- **ArchivePilotShare** – Share Extension surfaced from the system Share Sheet
- **ArchivePilotTests** – unit tests and mocks
- **ArchivePilotUITests** – smoke UI tests

## Requirements

- Xcode 16
- iOS 18.4 SDK (Apple Intelligence APIs)
- Developer account configured for iCloud Documents and App Groups `group.com.example.archivepilot`

## Building & Running

1. Open `ArchivePilot/ArchivePilot.xcodeproj` in Xcode.
2. Update the bundle identifiers and App Group/iCloud container identifiers to match your team.
3. Enable the **ArchivePilot** scheme and run on an iPhone 16 simulator or device (Apple Intelligence requires hardware support).
4. Use the Settings screen to pick archive root folders via the Folder Picker.

## Privacy

- Apple Intelligence runs fully on device.
- Optional OpenAI fallback is disabled by default. When enabled, only condensed snippets and folder lists are transmitted.
- API keys are stored in the Keychain linked to the App Group.

## Tests

Run unit tests via `Product → Test` or `xcodebuild test` targeting the `ArchivePilotTests` suite. Foundation Model interactions are abstracted so they can be mocked in CI.

