//
//  RecentFilesMenu.swift
//  Image Reader
//
//  Created by Joseph Wardell on 2/28/25.
//

import SwiftUI

@available(macOS 14.0, *)
public struct RecentFilesMenu: View {
    
    @Environment(\.recentFiles) var recentFiles
        
    @Environment(\.openDocument) var openDocument

    public init() {}

    public var body: some View {
        
        Menu("Open Recent") {
            
            if let files = recentFiles?.files, !files.isEmpty {
                ForEach(files, id: \.self) { file in
                    Button(file.displayName) {
                        open(file)
                    }
                }
            }
            else {
                Text("No Recent Images")
            }
        }
    }
    
    @MainActor
    private func open(_ file: RecentFiles.File) {
        guard let recentFiles else { return }
        
        openDocument.open(file: file, from: recentFiles)
    }

}

@available(macOS 14.0, *)
#Preview {
    RecentFilesMenu()
}
