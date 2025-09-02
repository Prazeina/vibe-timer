import SwiftUI
import AVFoundation
import UserNotifications
import AudioToolbox

// A struct to hold custom notification names, making them globally accessible
struct AppNotificationNames {
    static let restartTimer = Notification.Name("restartTimer")
}

// A simple model to hold timer data
struct ActiveTimer: Identifiable {
    let id = UUID()
    var label: String
    var totalSeconds: Int
    var remainingSeconds: Int
    var ringDuration: Double
    var ringtone: Ringtone
    var audioPlayer: AVAudioPlayer?
    var isPaused: Bool = false
}

// A model for preset timers
struct PresetTimer: Identifiable {
    let id = UUID()
    let label: String
    let durationInSeconds: Int
}

// Enum for our selectable ringtones
enum Ringtone: String, CaseIterable, Identifiable {
    case nature = "Nature"
    case lofi = "Lofi"
    case meditation = "Meditation"
    case morning_flower = "Morning Flower"
    
    var id: String { self.rawValue }
    
    var fileName: String {
        switch self {
        case .nature: return "nature.mp3"
        case .lofi: return "lofi.mp3"
        case .meditation: return "meditation.mp3"
        case .morning_flower: return "morning_flower.mp3"
        }
    }
}


struct ContentView: View {
    // MARK: - State Variables for UI
    @State private var hours = 0
    @State private var minutes = 1
    @State private var seconds = 0
    @State private var label = ""
    @State private var selectedRingDuration: Double = 5.0 // Default to 5 seconds
    @State private var selectedRingtone: Ringtone = .nature

    // State for running timers
    @State private var activeTimers: [ActiveTimer] = []
    
    // Used to check if the app is in the foreground or background
    @Environment(\.scenePhase) private var scenePhase
    
    // Timer to update the UI every second
    let uiUpdateTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Player for the silent audio track to keep the app alive in the background
    @State private var silentPlayer: AVAudioPlayer?
    
    // Background task identifier
    @State private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid


    let ringDurations = [
        (label: "5 Seconds", value: 5.0),
        (label: "15 Seconds", value: 15.0),
        (label: "25 Seconds", value: 25.0)
    ]
    
    let presets = [
          PresetTimer(label: "Egg 🥚", durationInSeconds: 480),       // 8 minutes
          PresetTimer(label: "Washing Machine 🧺", durationInSeconds: 3180),// 53 minutes
          PresetTimer(label: "Meditation 🧘‍♀️", durationInSeconds: 600),     // 10 minutes
          PresetTimer(label: "Power nap 😴", durationInSeconds: 1200),     // 20 minutes
          PresetTimer(label: "Pomodoro 🥷", durationInSeconds: 1800)       // 30 minutes
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Duration").padding(.leading, -16)) {
                    // Time Picker
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24) { Text("\($0) h").tag($0) }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: geometry.size.width / 3)
                            .clipped()
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60) { Text("\($0) m").tag($0) }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: geometry.size.width / 3)
                            .clipped()

                            Picker("Seconds", selection: $seconds) {
                                ForEach(0..<60) { Text("\($0) s").tag($0) }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: geometry.size.width / 3)
                            .clipped()
                        }
                    }
                    .frame(height: 150)
                }

                // MARK: - Control Buttons
                HStack {
                    Button(action: resetSetup) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Button(action: startTimer) {
                        Text("Start")
                            .font(.headline)
                            .frame(width: 80, height: 80)
                            .background(Color.green.opacity(0.4))
                            .foregroundColor(.green)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(totalSecondsInPicker == 0)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Section(header: Text("Settings").padding(.leading, -16)) {
                    HStack {
                        Text("Label")
                        TextField("Name", text: $label)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Alarm Duration", selection: $selectedRingDuration) {
                        ForEach(ringDurations, id: \.value) { duration in
                            Text(duration.label).tag(duration.value)
                        }
                    }
                    Picker("Ringtone", selection: $selectedRingtone) {
                        ForEach(Ringtone.allCases) { ringtone in
                            Text(ringtone.rawValue).tag(ringtone)
                        }
                    }
                }
                
                // MARK: - Active Timers List
                Section(header: Text("Active Timers").padding(.leading, -16)) {
                    if activeTimers.isEmpty {
                        Text("No active timers")
                            .foregroundColor(.gray)
                    } else {
                        ForEach($activeTimers) { $timer in
                            VStack(alignment: .leading) {
                                Text(timer.label)
                                    .font(.headline)
                                
                                HStack(alignment: .center) {
                                    Text(formatTime(seconds: timer.remainingSeconds))
                                        .font(.largeTitle)
                                        .fontWeight(.thin)
                                    
                                    Spacer()
                                    
                                    if timer.remainingSeconds > 0 {
                                        Button(action: { togglePause(for: timer.id) }) {
                                            Image(systemName: timer.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                                .font(.largeTitle)
                                                .foregroundColor(timer.isPaused ? .green : .orange)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        // Finished timer controls
                                        HStack {
                                            Button(action: { restartTimer(id: timer.id) }) {
                                                Image(systemName: "repeat.circle.fill")
                                                    .font(.largeTitle)
                                                    .foregroundColor(.green)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Button(action: { stopSoundAndRemove(id: timer.id) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.largeTitle)
                                                    .foregroundColor(.red)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: deleteTimer)
                    }
                }
                
                // MARK: - Presets Section
                Section(header: Text("Presets").padding(.leading, -16)) {
                    ForEach(presets) { preset in
                        Button(action: { startPresetTimer(preset: preset) }) {
                            HStack {
                                Text(preset.label)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(formatTime(seconds: preset.durationInSeconds))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Timer")
            .onReceive(uiUpdateTimer) { _ in
                updateAllTimers()
            }
            .onReceive(NotificationCenter.default.publisher(for: AppNotificationNames.restartTimer)) { notification in
                handleRestartNotification(from: notification)
            }
            .onAppear {
                checkNotificationPermissions()
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background:
                    if !activeTimers.isEmpty {
                        print("App going to background, playing silent sound to keep alive")
                        playSilentSound()
                    }
                case .active:
                    print("App becoming active, stopping silent sound")
                    silentPlayer?.stop()
                    
                    // End any background task when app becomes active
                    if backgroundTaskID != .invalid {
                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                        backgroundTaskID = .invalid
                    }
                    
                    // Reconfigure audio session when app becomes active
                    if !activeTimers.isEmpty {
                        do {
                            let audioSession = AVAudioSession.sharedInstance()
                            try audioSession.setCategory(.playback, mode: .default, options: [])
                            try audioSession.setActive(true)
                            print("Audio session reconfigured when app became active")
                            
                            // Try to play any sounds that failed while backgrounded
                            for (index, timer) in activeTimers.enumerated() {
                                if timer.audioPlayer == nil && timer.remainingSeconds <= 0 {
                                    print("Attempting to play delayed sound for: \(timer.label)")
                                    playSound(at: index)
                                    
                                    // Also try to play the sound multiple times to ensure it's heard
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        if self.activeTimers.indices.contains(index) && self.activeTimers[index].audioPlayer == nil {
                                            print("Retrying sound playback for: \(timer.label)")
                                            self.playSound(at: index)
                                        }
                                    }
                                }
                            }
                        } catch {
                            print("Failed to reconfigure audio session: \(error)")
                        }
                    }
                case .inactive:
                    print("App becoming inactive")
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var totalSecondsInPicker: Int {
        return (hours * 3600) + (minutes * 60) + seconds
    }

    // MARK: - Functions
    private func startTimer() {
        let totalSeconds = totalSecondsInPicker
        guard totalSeconds > 0 else { return }
        
        var newTimer = ActiveTimer(
            label: label.isEmpty ? "Timer" : label,
            totalSeconds: totalSeconds,
            remainingSeconds: totalSeconds,
            ringDuration: selectedRingDuration,
            ringtone: selectedRingtone
        )
        
        activeTimers.append(newTimer)
        scheduleNotification(for: newTimer)
        resetSetup()
    }

    private func startPresetTimer(preset: PresetTimer) {
        var newTimer = ActiveTimer(
            label: preset.label,
            totalSeconds: preset.durationInSeconds,
            remainingSeconds: preset.durationInSeconds,
            ringDuration: selectedRingDuration,
            ringtone: selectedRingtone
        )
        
        activeTimers.append(newTimer)
        scheduleNotification(for: newTimer)
    }

    private func restartTimer(id: UUID) {
        guard let originalTimerIndex = activeTimers.firstIndex(where: { $0.id == id }) else { return }
        let originalTimer = activeTimers[originalTimerIndex]
        
        var newTimer = ActiveTimer(
            label: originalTimer.label,
            totalSeconds: originalTimer.totalSeconds,
            remainingSeconds: originalTimer.totalSeconds,
            ringDuration: originalTimer.ringDuration,
            ringtone: originalTimer.ringtone
        )
        
        stopSoundAndRemove(id: id)
        activeTimers.append(newTimer)
        scheduleNotification(for: newTimer)
    }

    private func handleRestartNotification(from notification: Notification) {
        guard let userInfo = notification.userInfo,
              let totalSeconds = userInfo["totalSeconds"] as? Int,
              let label = userInfo["label"] as? String,
              let ringtoneRawValue = userInfo["ringtone"] as? String,
              let ringtone = Ringtone(rawValue: ringtoneRawValue) else {
            return
        }
        
        var newTimer = ActiveTimer(
            label: label,
            totalSeconds: totalSeconds,
            remainingSeconds: totalSeconds,
            ringDuration: selectedRingDuration,
            ringtone: ringtone
        )
        
        activeTimers.append(newTimer)
        scheduleNotification(for: newTimer)
    }

    private func togglePause(for id: UUID) {
        if let index = activeTimers.firstIndex(where: { $0.id == id }) {
            activeTimers[index].isPaused.toggle()
            if activeTimers[index].isPaused {
                cancelNotification(for: id)
            } else {
                scheduleNotification(for: activeTimers[index])
            }
        }
    }

    private func updateAllTimers() {
        for id in activeTimers.map({ $0.id }) {
            guard let index = activeTimers.firstIndex(where: { $0.id == id }) else { continue }
            
            guard !activeTimers[index].isPaused else { continue }
            
            if activeTimers[index].remainingSeconds > 0 {
                activeTimers[index].remainingSeconds -= 1
            } else if activeTimers[index].audioPlayer == nil {
                playSound(at: index)
                cancelNotification(for: activeTimers[index].id)
                
                if activeTimers[index].ringDuration != Double.infinity {
                    let timerId = activeTimers[index].id
                    DispatchQueue.main.asyncAfter(deadline: .now() + activeTimers[index].ringDuration) {
                        stopSoundAndRemove(id: timerId)
                    }
                }
            }
        }
    }
    
    private func deleteTimer(at offsets: IndexSet) {
        let idsToDelete = offsets.map { activeTimers[$0].id }
        for id in idsToDelete {
            cancelNotification(for: id)
            stopSoundAndRemove(id: id)
        }
        if activeTimers.isEmpty {
            silentPlayer?.stop()
        }
    }
    
    private func stopSoundAndRemove(id: UUID) {
        if let index = activeTimers.firstIndex(where: { $0.id == id }) {
            activeTimers[index].audioPlayer?.stop()
            activeTimers.remove(at: index)
        }
        
        // Only deactivate audio session if no timers are playing sounds
        if activeTimers.allSatisfy({ $0.audioPlayer == nil }) {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                print("Audio session deactivated")
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
        
        if activeTimers.isEmpty {
            silentPlayer?.stop()
            print("All timers stopped, silent player stopped")
        }
    }
    
    private func resetSetup() {
        hours = 0
        minutes = 1
        seconds = 0
        label = ""
    }
    
    private func formatTime(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    // MARK: - Live Activity & Notification Functions
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                        if success {
                            print("Notification permission granted")
                        } else if let error = error {
                            print("Notification permission error: \(error.localizedDescription)")
                        }
                    }
                case .denied:
                    print("Notification permission denied")
                case .authorized:
                    print("Notification permission already authorized")
                case .provisional:
                    print("Notification permission provisional")
                case .ephemeral:
                    print("Notification permission ephemeral")
                @unknown default:
                    break
                }
            }
        }
    }
    

    
    private func playSound(at index: Int) {
        guard activeTimers.indices.contains(index) else { return }
        
        let timer = activeTimers[index]
        guard let soundURL = Bundle.main.url(forResource: timer.ringtone.fileName, withExtension: nil) else {
            print("Sound file not found: \(timer.ringtone.fileName)")
            return
        }
        
        // ALWAYS schedule notification first - this is the most reliable method
        scheduleLocalNotificationFallback(for: timer)
        
        // Start background task to keep app alive for audio playback
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "TimerAudio") {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
        
        do {
            // Configure audio session for background playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 1.0
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            activeTimers[index].audioPlayer = audioPlayer
            
            print("✅ SUCCESS: Playing sound: \(timer.ringtone.fileName)")
            
            // End background task after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + timer.ringDuration) {
                if self.backgroundTaskID != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                    self.backgroundTaskID = .invalid
                }
            }
            
        } catch {
            print("❌ FAILED: Audio session error: \(error.localizedDescription)")
            print("📱 Using notification fallback instead")
            
            // Try system sound as last resort
            AudioServicesPlaySystemSound(1005) // Default notification sound
            print("🔔 Played system notification sound")
            
            // End background task on error
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
    }
    
    private func playSilentSound() {
        guard let soundURL = Bundle.main.url(forResource: "silence", withExtension: "mp3") else {
            print("Silent sound file not found.")
            return
        }
        
        // Start background task for silent sound
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SilentAudio") {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
        
        do {
            // Configure audio session for background playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            
            // Always try to activate
            try audioSession.setActive(true)
            
            silentPlayer = try AVAudioPlayer(contentsOf: soundURL)
            silentPlayer?.numberOfLoops = -1
            silentPlayer?.volume = 0.0
            silentPlayer?.prepareToPlay()
            silentPlayer?.play()
            
            print("Playing silent sound to keep app alive in background")
        } catch {
            print("Failed to play silent sound: \(error.localizedDescription)")
            // If silent sound fails, we'll rely on notifications
            if backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTaskID)
                backgroundTaskID = .invalid
            }
        }
    }

    
    private func scheduleLocalNotificationFallback(for timer: ActiveTimer) {
        // Create an immediate notification with multiple alerts
        let content = UNMutableNotificationContent()
        content.title = timer.label
        content.body = "Time's up!"
        
        // Try to use custom ringtone in notification
        let customSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: timer.ringtone.fileName))
        content.sound = customSound
        
        content.badge = 1
        content.categoryIdentifier = "TIMER_ACTIONS"
        
        // Add user info for restart functionality
        content.userInfo = [
            "totalSeconds": timer.totalSeconds,
            "label": timer.label,
            "ringtone": timer.ringtone.rawValue,
            "shouldPlaySound": true
        ]
        
        // Schedule multiple notifications to ensure user hears it
        for i in 0..<3 {
            let delay = max(0.1, TimeInterval(i * 2))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: "fallback-\(timer.id.uuidString)-\(i)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Fallback notification \(i) failed: \(error.localizedDescription)")
                } else {
                    print("Fallback notification \(i) scheduled for: \(timer.label)")
                }
            }
        }
    }
    
    private func scheduleNotification(for timer: ActiveTimer) {
        // Schedule multiple notifications to ensure user hears it
        for i in 0..<5 {
            let content = UNMutableNotificationContent()
            content.title = timer.label
            content.body = "Time's up!"
            
            // Try to use custom ringtone in notification
            let customSound = UNNotificationSound(named: UNNotificationSoundName(rawValue: timer.ringtone.fileName))
            content.sound = customSound
            
            content.categoryIdentifier = "TIMER_ACTIONS"
            content.badge = 1
            
            content.userInfo = [
                "totalSeconds": timer.totalSeconds,
                "label": timer.label,
                "ringtone": timer.ringtone.rawValue,
                "shouldPlaySound": true
            ]

            // Schedule notifications at different intervals
            let delay = max(1.0, TimeInterval(timer.remainingSeconds + (i * 2)))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: "\(timer.id.uuidString)-\(i)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification \(i): \(error.localizedDescription)")
                } else {
                    print("Notification \(i) scheduled successfully for timer: \(timer.label) in \(delay) seconds")
                }
            }
        }
    }
    
    private func cancelNotification(for id: UUID) {
        // Cancel all notifications for this timer (including multiple scheduled ones)
        var identifiers: [String] = []
        for i in 0..<5 {
            identifiers.append("\(id.uuidString)-\(i)")
        }
        identifiers.append("fallback-\(id.uuidString)-0")
        identifiers.append("fallback-\(id.uuidString)-1")
        identifiers.append("fallback-\(id.uuidString)-2")
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
