import SwiftUI
import AVFoundation // Needed for playing sounds
import UserNotifications // Required for background notifications
import ActivityKit // Required for Live Activities

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
    var activity: Activity<TimerActivityAttributes>? // Holds the Live Activity session
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
    
    // NOTE: You must add these sound files to your project for notifications to work.
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
                                Spacer()
                                Text(formatTime(seconds: preset.durationInSeconds))
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.white)
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
        
        startLiveActivity(for: &newTimer)
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
        
        startLiveActivity(for: &newTimer)
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
        startLiveActivity(for: &newTimer)
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
        
        startLiveActivity(for: &newTimer)
        activeTimers.append(newTimer)
        scheduleNotification(for: newTimer)
    }

    private func togglePause(for id: UUID) {
        if let index = activeTimers.firstIndex(where: { $0.id == id }) {
            activeTimers[index].isPaused.toggle()
            if activeTimers[index].isPaused {
                cancelNotification(for: id)
                Task {
                    await activeTimers[index].activity?.end(dismissalPolicy: .immediate)
                }
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
                if scenePhase == .active {
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
    }
    
    private func deleteTimer(at offsets: IndexSet) {
        let idsToDelete = offsets.map { activeTimers[$0].id }
        for id in idsToDelete {
            cancelNotification(for: id)
            stopSoundAndRemove(id: id)
        }
    }
    
    private func stopSoundAndRemove(id: UUID) {
        // Find the index of the timer to remove.
        if let index = activeTimers.firstIndex(where: { $0.id == id }) {
            // Get the activity session *before* removing the timer from the array.
            let activity = activeTimers[index].activity
            
            // Stop the sound player.
            activeTimers[index].audioPlayer?.stop()
            
            // Remove the timer from the array.
            activeTimers.remove(at: index)
            
            // Now, safely end the activity outside of the array access.
            Task {
                await activity?.end(dismissalPolicy: .immediate)
            }
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
    private func startLiveActivity(for timer: inout ActiveTimer) {
        let attributes = TimerActivityAttributes(timerName: timer.label)
        let state = TimerActivityAttributes.ContentState(endTime: .now + TimeInterval(timer.remainingSeconds))
        
        do {
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                contentState: state,
                pushType: nil)
            timer.activity = activity // Store the activity session
            print("Live Activity started: \(activity.id)")
        } catch (let error) {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func playSound(at index: Int) {
        guard activeTimers.indices.contains(index) else { return }
        
        let timer = activeTimers[index]
        guard let soundURL = Bundle.main.url(forResource: timer.ringtone.fileName, withExtension: nil) else {
            print("Sound file not found: \(timer.ringtone.fileName)")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
            activeTimers[index].audioPlayer = audioPlayer
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
    
    private func scheduleNotification(for timer: ActiveTimer) {
        let content = UNMutableNotificationContent()
        content.title = timer.label
        content.body = "Time's up!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: timer.ringtone.fileName))
        content.categoryIdentifier = "TIMER_ACTIONS"
        
        content.userInfo = [
            "totalSeconds": timer.totalSeconds,
            "label": timer.label,
            "ringtone": timer.ringtone.rawValue
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timer.remainingSeconds), repeats: false)
        let request = UNNotificationRequest(identifier: timer.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func cancelNotification(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
