//
//  ReportsRecentFiles.swift
//  Image Reader
//
//  Created by Joseph Wardell on 3/26/25.
//

import SwiftUI

@available(macOS 14.0, *)
fileprivate struct ReportsRecentFiles: ViewModifier {
    
    @Environment(\.documentConfiguration) var documentConfiguration
    @Environment(\.recentFiles) var recentFiles

    func body(content: Content) -> some View {
        content
            .onAppear {
                
                guard let documentConfiguration,
                        let file = RecentFiles.File(documentConfiguration)
                else { return }
                
                // don't worry about errors here.
                // either it works or the file doesn't get added to the RecentFiles
                // either way, there's nothing to do to recover
                try? recentFiles?.add(file)
            }
    }
}

@available(macOS 14.0, *)
public extension View {
    func reportsToRecentFiles() -> some View {
        modifier(ReportsRecentFiles())
    }
    
    func reports(to recentFiles: RecentFiles?) -> some View {
        self
            .modifier(ReportsRecentFiles())
            .environment(\.recentFiles, recentFiles)
    }
}
