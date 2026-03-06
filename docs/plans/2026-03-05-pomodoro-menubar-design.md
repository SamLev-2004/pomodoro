# Pomodoro Menu Bar App — Design Doc
**Date:** 2026-03-05
**Stack:** Swift, SwiftUI, macOS 13+

---

## Overview

A native macOS menu bar Pomodoro timer. Displays an animated arc icon that drains as the session progresses. Clicking the icon opens a minimal popover with controls. A separate settings window handles customization. System-adaptive (follows macOS light/dark mode).

---

## Architecture

```
PomodoroApp (SwiftUI App)
├── MenuBarExtra
│   ├── ArcTimerView        ← animated arc icon in the menu bar
│   └── ControlPopover      ← minimal popover (start/pause/reset + session label)
├── SettingsWindow          ← separate SwiftUI Settings scene
└── TimerStore (ObservableObject)
    ├── Timer state (running, paused, idle)
    ├── Session type (work, short break, long break)
    ├── Progress (0.0 → 1.0, drives the arc)
    └── UserDefaults-backed settings
```

`TimerStore` is the single source of truth — an `ObservableObject` injected as an `@EnvironmentObject`. A Combine `Timer.publish` ticks every second and updates progress. The arc redraws from the `progress` value.

---

## UI Components

### Menu Bar Arc Icon
- `Canvas`-drawn circular arc, drains clockwise as session progresses
- Color by session type: tomato red (work), mint green (short break), blue (long break)
- Fixed 18×18pt frame to match native menu bar icon sizing

### Control Popover (opens on click)
- Session label: e.g. `Work · 25:00`
- Large monospaced bold countdown
- Three buttons: Start/Pause, Reset, Skip
- Session dot indicators: e.g. `● ● ○ ○` (progress through 4-session cycle)

### Settings Window
Triggered via right-click menu or gear icon in popover. Sections:
- **Durations:** work (default 25min), short break (5min), long break (15min) — stepper fields
- **Cycle:** sessions before long break (default 4)
- **Sounds:** toggle on/off, pick from built-in system sounds
- **Auto-start:** toggle to auto-start next session on completion
- **Keyboard shortcut:** configurable via `KeyboardShortcuts` package

---

## Data Flow & State

```
UserDefaults ←→ TimerSettings (struct)
                    ↓
              TimerStore (@ObservableObject)
              ├── phase: .work | .shortBreak | .longBreak
              ├── secondsRemaining: Int
              ├── isRunning: Bool
              ├── sessionCount: Int (0–3, resets after long break)
              └── progress: Double (computed, 0.0→1.0)
                    ↓ @EnvironmentObject
        ┌─────────────────────────┐
   ArcTimerView           ControlPopover
   (reads progress)       (reads + writes via methods)
                                 ↓
                    store.start() / .pause() / .reset() / .skip()
```

**On session completion:**
1. Play sound (if enabled)
2. Fire `UNUserNotification`
3. Auto-start next session (if enabled)
4. Advance `sessionCount`

**Settings changes** write immediately to `UserDefaults`. If the active session's duration changes, reset the current timer to the new duration.

---

## Error Handling

- **Notification permission denied:** silently skip notifications, no crash
- **Mac sleep/backgrounded:** use `Date`-based elapsed time on resume instead of trusting tick count, so the timer stays accurate across sleep

---

## Testing

- **Unit tests:** `TimerStore` — session transitions, auto-start logic, duration changes mid-session
- **Manual checklist:**
  - Arc animates correctly through a full session
  - Popover opens/closes on click
  - Settings persist across app restart
  - Keyboard shortcut triggers start/pause
  - Notifications fire on session completion
  - Timer resumes correctly after Mac sleep
