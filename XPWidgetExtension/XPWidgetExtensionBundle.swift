//
//  XPWidgetExtensionBundle.swift
//  XPWidgetExtension
//
//  Created by Quinn Darling on 1/11/25.
//

import WidgetKit
import SwiftUI

// @main
struct XPWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        XPPathwayWidget()
        XPWidgetExtensionControl()
        XPWidgetExtensionLiveActivity()
    }
}
