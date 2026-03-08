# Pomodoro

A sleek Pomodoro timer that lives in your Mac menu bar — with a tomato that fills up as you focus.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- Animated tomato icon that fills as the timer counts down
- Customizable work, short break, and long break durations
- Desktop notifications when sessions complete
- Global keyboard shortcut (⌘⇧P)
- Auto-start next session option
- Built-in sound alerts
- Adapts to macOS light & dark mode
- Zero Dock clutter — pure menu bar app

## Installation

1. Download `Pomodoro.dmg` from the [latest release](https://github.com/SamLev-2004/pomodoro/releases/latest)
2. Open the DMG and drag `Pomodoro.app` to your Applications folder
3. Before opening for the first time, run this in Terminal:
   ```bash
   xattr -cr /Applications/Pomodoro.app
   ```
4. Open Pomodoro from Applications — the tomato icon will appear in your menu bar

> **Note:** The Terminal step is needed because the app is not yet notarized with Apple. You only need to do this once.

## Building from Source

**Requirements:** Xcode 15+, macOS 14+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
git clone https://github.com/SamLev-2004/pomodoro.git
cd pomodoro
xcodegen generate
xcodebuild -project Pomodoro.xcodeproj -scheme Pomodoro -configuration Release build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

The built app will be in `DerivedData` or the directory specified by `CONFIGURATION_BUILD_DIR`.

## License

MIT
