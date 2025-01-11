//
//  XPWidgetExtensionLiveActivity.swift
//  XPWidgetExtension
//
//  Created by Quinn Darling on 1/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct XPWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct XPWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: XPWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension XPWidgetExtensionAttributes {
    fileprivate static var preview: XPWidgetExtensionAttributes {
        XPWidgetExtensionAttributes(name: "World")
    }
}

extension XPWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: XPWidgetExtensionAttributes.ContentState {
        XPWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: XPWidgetExtensionAttributes.ContentState {
         XPWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: XPWidgetExtensionAttributes.preview) {
   XPWidgetExtensionLiveActivity()
} contentStates: {
    XPWidgetExtensionAttributes.ContentState.smiley
    XPWidgetExtensionAttributes.ContentState.starEyes
}
