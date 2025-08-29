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
* Get Audio Files: Make sure you have sound files (e.g., nature.mp3, lofi.mp3) that are less than 30 seconds long.
* Add to Xcode: Drag these files into your Xcode Project Navigator. When prompted, ensure "Copy items if needed" and your app's target are checked.
* Verify Filenames: Make sure the filenames in your Ringtone enum inside ContentView.swift exactly match the files you added.
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
* When you run the app for the first time, you must tap "Allow" on the notification permission pop-up
