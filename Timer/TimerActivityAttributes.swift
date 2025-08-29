import SwiftUI
import WidgetKit
import ActivityKit

// 1. Define the data for the Live Activity
struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // This is the dynamic data that will update
        var endTime: Date
    }

    // This is static data that doesn't change
    var timerName: String
}

// 2. Create the UI for the Live Activity
struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // MARK: Lock Screen UI
            HStack {
                // In a real app, these buttons would be implemented with App Intents
                HStack {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                    
                    Image(systemName: "xmark")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }
                
                Text(context.attributes.timerName)
                    .font(.headline)
                    .padding(.leading)

                Spacer()
                
                Text(timerInterval: context.state.endTime...Date.distantFuture, countsDown: true)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            // MARK: Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        // In a real app, these buttons would be implemented with App Intents
                        Image(systemName: "pause.fill")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.orange)
                            .clipShape(Circle())
                        
                        Image(systemName: "xmark")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.timerName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.endTime...Date.distantFuture, countsDown: true)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(timerInterval: context.state.endTime...Date.distantFuture, countsDown: true)
                    .font(.caption)
                    .fontWeight(.semibold)
            } minimal: {
                Image(systemName: "timer")
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
