//
//  OpenDocumentAction+RecentFiles.swift
//  Image Reader
//
//  Created by Joseph Wardell on 3/24/25.
//

import SwiftUI

@available(macOS 14.0, *)
extension OpenDocumentAction {
    func open(file: RecentFiles.File, from recentFiles: RecentFiles) {
        Task {
            if let urlToOpen = recentFiles.currentURL(for: file) {
                try await self.callAsFunction(at: urlToOpen)
            }
            
//            try await recentFiles.usingURL(for: file) {
//                print($0)
//                try await self.callAsFunction(at: $0)
//            }
        }
    }
}
