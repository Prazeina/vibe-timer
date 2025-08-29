//
//  TimerApp.swift
//  Timer
//
//  Created by prazeina on 29/08/2025.
//

import SwiftUI

@main
struct TimerApp: App {
    // Use the AppDelegateAdaptor to connect our delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
