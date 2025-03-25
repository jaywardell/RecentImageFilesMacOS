//
//  RecentFiles+EnvironmentValues.swift
//  Image Reader
//
//  Created by Joseph Wardell on 3/25/25.
//

import SwiftUI

@available(macOS 14.0, *)
extension EnvironmentValues {
    @Entry var recentFiles: RecentFiles?
}
