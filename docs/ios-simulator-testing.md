# iOS Simulator Testing for Ralph

This document describes how to enable iOS simulator testing in Ralph for validating iOS app implementations.

## Overview

Ralph can validate iOS UI implementations by:
1. Building the app with `xcodebuild`
2. Installing and launching on iOS Simulator
3. Capturing screenshots
4. Analyzing screenshots against acceptance criteria

This is equivalent to browser testing for web applications.

## Prerequisites

- **Xcode** installed with iOS Simulator runtimes
- **iOS Simulator runtime** downloaded (Xcode > Settings > Platforms > iOS)
- **Project scheme** properly configured in Xcode

## Quick Start

### 1. Use the validation script

```bash
./scripts/ios-simulator-validate.sh <scheme> <bundle_id> [device_name]

# Example
./scripts/ios-simulator-validate.sh LocalPhotosApp com.ralph.LocalPhotosApp "iPhone 17 Pro"
```

### 2. Manual validation

```bash
# Boot simulator
xcrun simctl boot "iPhone 17 Pro"

# Build
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install
xcrun simctl install booted /path/to/MyApp.app

# Launch
xcrun simctl launch booted com.example.MyApp

# Screenshot
xcrun simctl io booted screenshot /tmp/screenshot.png
```

## Defining Success Criteria in prd.json

Add `simulatorValidation` to user stories that require UI verification:

```json
{
  "id": "US-001",
  "title": "Tab navigation",
  "description": "...",
  "acceptanceCriteria": [
    "Display 3 tabs: Gallery, Collections, Create",
    "Each tab has SF Symbol icon",
    "Tabs are switchable"
  ],
  "simulatorValidation": {
    "scheme": "LocalPhotosApp",
    "bundleId": "com.ralph.LocalPhotosApp",
    "screens": [
      {
        "name": "Initial Launch",
        "action": "launch",
        "expectedElements": [
          "Tab bar at bottom",
          "3 tab icons visible",
          "Gallery tab selected by default"
        ]
      },
      {
        "name": "Collections Tab",
        "action": "tap_tab:Collections",
        "expectedElements": [
          "Collections title visible",
          "People section header",
          "Albums section header"
        ]
      }
    ]
  },
  "priority": 1,
  "passes": false
}
```

## Validation Schema

### Screen Object

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Human-readable screen name |
| `action` | string | Action to perform (see below) |
| `expectedElements` | array | List of UI elements to verify |
| `screenshot` | string | (optional) Path to save screenshot |

### Actions

| Action | Description |
|--------|-------------|
| `launch` | Launch app (default first screen) |
| `tap_tab:<name>` | Tap tab bar item by name |
| `tap_button:<label>` | Tap button by label |
| `navigate_back` | Tap back button |
| `wait:<seconds>` | Wait for specified seconds |
| `screenshot_only` | Just capture screenshot |

## Expected Elements

When defining `expectedElements`, be specific but flexible:

### Good examples:
- "Tab bar with 3 tabs"
- "Gallery title at top"
- "Photo grid with multiple images"
- "Create button visible"
- "Empty state message when no photos"

### Avoid:
- Pixel-perfect coordinates
- Exact color values
- Specific asset filenames

## Validation Workflow

Ralph follows this workflow for iOS UI stories:

```
1. Read story with simulatorValidation
2. Implement the feature
3. Run xcodebuild (must pass)
4. For each screen in simulatorValidation:
   a. Perform action
   b. Capture screenshot
   c. Analyze screenshot for expectedElements
   d. Record results in progress.txt
5. If all screens pass, mark story as passes: true
6. If any screen fails, document failure and iterate
```

## Troubleshooting

### No simulator runtime
```bash
# Download iOS runtime
xcodebuild -downloadPlatform iOS
```

### Simulator won't boot
```bash
# Kill simulator service and retry
killall -9 com.apple.CoreSimulator.CoreSimulatorService
xcrun simctl boot "iPhone 17 Pro"
```

### App won't install
```bash
# Erase simulator and retry
xcrun simctl erase booted
```

### Screenshot is black
```bash
# Wait for app to load
sleep 3
xcrun simctl io booted screenshot /tmp/screenshot.png
```

## Integration with Ralph Loop

When `ralph.sh` runs, it will:

1. Check if current story has `simulatorValidation`
2. If yes, run the validation script after build passes
3. Capture and analyze screenshots
4. Only mark `passes: true` if UI validation succeeds

## Example: Complete Story with Validation

```json
{
  "id": "US-004",
  "title": "Display photo grid in Gallery tab",
  "description": "As a user, I want to see all my photos in a grid.",
  "acceptanceCriteria": [
    "Display photos in 3-column grid",
    "Thumbnails maintain square aspect ratio",
    "Grid scrolls smoothly"
  ],
  "simulatorValidation": {
    "scheme": "LocalPhotosApp",
    "bundleId": "com.ralph.LocalPhotosApp",
    "screens": [
      {
        "name": "Photo Grid",
        "action": "launch",
        "expectedElements": [
          "Gallery title",
          "3-column grid layout",
          "Square photo thumbnails",
          "Tab bar at bottom"
        ],
        "screenshot": "/tmp/us004_photo_grid.png"
      }
    ]
  },
  "priority": 4,
  "passes": false
}
```

## Tips for Writing Validation Criteria

1. **Be descriptive**: "3-column photo grid" is better than "grid"
2. **Include navigation**: Always verify tab bar/nav bar is present
3. **Test states**: Include empty state, loading state if applicable
4. **One screen per action**: Don't combine multiple screens in one check
5. **Save screenshots**: Use `screenshot` field for debugging

## Future Enhancements

- Accessibility tree validation (requires `idb` tool)
- Automated tap/gesture simulation
- Visual diff comparison between screenshots
- CI/CD integration with headless simulators
