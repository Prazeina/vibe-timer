# vibe-timer
Custom Timer App
Timer App Overview
This is a full-featured, custom timer application for iOS built with SwiftUI. The app allows users to create, manage, and customize multiple timers with advanced features like custom alarm durations, selectable ringtones, and lock screen integration with Live Activities. It is designed to be a robust and user-friendly alternative to the native iOS timer.
✨ Features
* Custom Timer Creation: Set timers for any duration using an intuitive wheel picker for hours, minutes, and seconds.
* Multiple Timers: Run several timers simultaneously, each displayed in a clean, organized list.
* Customizable Alarms:
    * Alarm Duration: Choose how long the alarm will ring when the app is open (e.g., 5, 15, or 25 seconds).
    * Custom Ringtones: Select from a list of unique, built-in ringtones.
* Timer Presets: Quickly start common timers like "Egg Boil" or "Pomodoro" with a single tap.
* Background Functionality:
    * Lock Screen Notifications: Timers will reliably ring on the lock screen using the iOS User Notifications framework.
    * Live Activities: Active timers are displayed on the lock screen and in the Dynamic Island, showing the countdown in real-time.
* Interactive Controls:
    * Pause and resume running timers.
    * Restart or delete finished timers directly from the app or the lock screen.
    * Cancel a running timer by swiping left on it.
📂 Project Structure
The project is organized into the following key files:
* ContentView.swift: The main view of the app. It contains all the UI for setting up and managing timers, as well as the core logic for starting, stopping, and updating them.
* TimerApp.swift: The main entry point for the application. It uses an AppDelegate to handle app-level events.
* AppDelegate.swift: This file is crucial for handling background notifications. It requests user permission for notifications and sets up custom notification actions (like "Restart" and "Cancel").
* TimerActivityWidget.swift: This file defines the entire look and feel of the Live Activity that appears on the lock screen and in the Dynamic Island.
🚀 Setup Instructions
To get the project running correctly on your own device, follow these steps:
1. Add Custom Sound Files
The app will not ring unless you add your own audio files to the project.
* Get Audio Files: Use short audio files (< 30s). For lock-screen notifications, iOS supports bundled sounds only with extensions: `.caf`, `.aiff`/`.aif`, or `.wav`. In-app playback also supports `.mp3`/`.m4a`.
* Add to Xcode: Drag these files into your Xcode Project Navigator. When prompted, ensure "Copy items if needed" and your app's target are checked.
* Verify Filenames: Ensure the base names in the `Ringtone` enum inside `ContentView.swift` match your files. Provide at least one notification-compatible file (e.g., `nature.caf`).
* Time Sensitive: In iOS Settings → Notifications → vibe-timer, enable "Time Sensitive Notifications" so alerts can ring on the lock screen even during Focus modes.
2. Enable Live Activities
* In your project settings, go to the "Info" tab.
* Add a new key called "Supports Live Activities" and set its value to "YES".
3. Create the Widget Extension
Live Activities require a separate Widget Extension target.
* Go to File > New > Target... and select the Widget Extension template.
* Name it TimerWidget and uncheck "Include Configuration Intent."
* Replace the contents of the new TimerWidget.swift file with the code from your TimerActivityWidget.swift file.
* In the Target Membership for TimerActivityWidget.swift, make sure only the TimerWidget target is checked.
4. Run the App
* Connect your iPhone and select it as the run destination.
* When you run the app for the first time, tap "Allow" on the notification permission pop-up. If alerts are not audible on the lock screen, verify that a `.caf`/`.aiff`/`.wav` file is present in the app bundle and that Time Sensitive is enabled.
