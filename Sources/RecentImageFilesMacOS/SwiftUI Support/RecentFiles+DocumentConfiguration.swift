//
//  RecentFiles+DocumentConfiguration.swift
//  Image Reader
//
//  Created by Joseph Wardell on 3/25/25.
//

import SwiftUI

@available(macOS 14.0, *)
extension RecentFiles.File {
    
    init?(_ configuration: DocumentConfiguration) {
        guard let fileURL = configuration.fileURL else { return nil }
        
        self.init(fileURL)
    }
}
