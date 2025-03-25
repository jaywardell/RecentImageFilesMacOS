//
//  URL+FileSystem.swift
//  Image Reader
//
//  Created by Joseph Wardell on 3/24/25.
//

import Foundation

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
