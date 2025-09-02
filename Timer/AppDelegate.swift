import UIKit
import UserNotifications
import AVFoundation

// The AppDelegate now handles all notification logic directly
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 1. Set this class as the notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // 2. Define the notification actions
        let restartAction = UNNotificationAction(identifier: "RESTART_ACTION", title: "Restart", options: [])
        let cancelAction = UNNotificationAction(identifier: "CANCEL_ACTION", title: "Cancel", options: [.destructive])
        
        // 3. Define the category with the actions
        let timerCategory = UNNotificationCategory(identifier: "TIMER_ACTIONS", actions: [restartAction, cancelAction], intentIdentifiers: [], options: [])
        
        // 4. Register the category with the system
        UNUserNotificationCenter.current().setNotificationCategories([timerCategory])
        
        // 5. Request permission from the user
        requestNotificationAuthorization()

        // Configure audio session for background playback
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        return true
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notification authorization granted.")
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo

        if response.actionIdentifier == "RESTART_ACTION" {
            // Post a notification to tell ContentView to restart the timer
            NotificationCenter.default.post(name: AppNotificationNames.restartTimer, object: nil, userInfo: userInfo)
        }
        
        // For both "Restart" and "Cancel", we remove the notification from the lock screen
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
        
        completionHandler()
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
