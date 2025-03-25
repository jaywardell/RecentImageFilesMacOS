//
//  RecentFiles.swift
//  Image Reader
//
//  Created by Joseph Wardell on 2/27/25.
//

import Foundation
import Observation
import UniformTypeIdentifiers

/*
 TODO: use security scoped bookmarks
 see https://www.avanderlee.com/swift/security-scoped-bookmarks-for-url-access/
 
 I couldn't get it to work.
 So I copy files into a temporary directory instead
 */

@available(macOS 14.0, *)
@Observable
public final class RecentFiles {
    
    enum Error: Swift.Error {
        case invalidURL
        case fileAlreadyExists
    }
    
    let directory: URL
    let limit: Int
    
    public struct File: Equatable, Hashable, Codable, Sendable {
        fileprivate let fileURL: URL
        let displayName: String
        let type: UTType
        let date: Date
        
        var preferredFileNameExtension: String {
            type.preferredFilenameExtension ?? fileURL.pathExtension
        }
        
        /// sometimes, a file may end up in the recent files list
        /// that's been copied from a web URL
        /// or from the photos library
        /// in those cases, this should return false
        var representsFileSystemFile: Bool {
            !fileURL.absoluteString.hasPrefix(URL.temporaryDirectory.absoluteString)
        }
        
        public init?(_ fileURL: URL,
              date: Date = .now,
              suggestedName: String? = nil) {
                        
            guard fileURL.isFileURL,
                  let components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false),
                  FileManager().fileExists(atPath: components.path) else {
                return nil
            }
            
            let filename = fileURL.deletingPathExtension().lastPathComponent
            guard !filename.isEmpty else { return nil }

            self.displayName = suggestedName ?? filename

            self.fileURL = fileURL

            // NOTE: since we're only getting the UTType from the file name
            // it's possible that a mislabeled file
            // could be reported with the wrong UTType
            // (e.g. the user mislables a .jpg file as .gif for some reason)
            // that's okay for our use case
            // we just want to tell the user
            // the kind of file that they would think it is
            // from looking at its metadata (e.g. its extension)
            let ext = fileURL.pathExtension
            guard let uttype = UTType(filenameExtension: ext) else { return nil }
            self.type = uttype

            self.date = date
        }
    }
    
    struct Archive: Codable {
        var files: [File]
        var copiedFiles: [URL : URL]
        static var empty: Archive { Archive(files: [], copiedFiles: [:]) }
    }
    private(set) var archive: Archive
    var files: [File] { archive.files }

    func nameForFile(at url: URL) -> String {
        let file = files.first {
            $0.fileURL == url
        }
        if let file { return file.displayName }
  
        for (key, value) in archive.copiedFiles {
            if value == url {
                return nameForFile(at: key)
            }
        }

        return url.lastPathComponent
    }
    
    public func add(_ file: File) throws {
                
        let fm = FileManager()
        while archive.files.count > limit - 1 {
            let removed = archive.files.removeLast()
            if let toRemove = archive.copiedFiles[removed.fileURL] {
                do {
                    try fm.removeItem(at: toRemove)
                }
                catch {
                    print("Error when trying to remove file at \(toRemove) due to space considerations: \(error.localizedDescription)")
                }
            }
        }
        
        if let index = archive.files.firstIndex(where: { thisFile in
            archive.copiedFiles[thisFile.fileURL] == file.fileURL
        }) {
            let removed = archive.files.remove(at: index)
            archive.files.insert(removed, at: 0)
            return
        }
        
        if let index = archive.files.firstIndex(where: { thisFile in
            thisFile.fileURL == file.fileURL
        }) {
            archive.files.remove(at: index)
            archive.files.insert(file, at: 0)
            return
        }
        archive.files.insert(file, at: 0)
        
        let newURL = directory.appending(component: String(file.hashValue) + "." + file.preferredFileNameExtension)
        archive.copiedFiles[file.fileURL] = newURL
        
        if !fm.fileExists(atPath: newURL.path()) {
            try fm.copyItem(at: file.fileURL, to: newURL)
        }
        
        store()
    }
    
    public func forget(_ file: File) {
        guard let index = archive.files.firstIndex(of: file) else { return }
        
        archive.files.remove(at: index)
        archive.copiedFiles.removeValue(forKey: file.fileURL)
        
        assert(archive.files.count == archive.copiedFiles.count)
        
        store()
    }
    
    public func clear() {
        archive = .empty
        
        let fm = FileManager()
        let removedURL = directory.deletingLastPathComponent().appending(component: "olddocuments")
        try! fm.moveItem(at: directory, to: removedURL)
        try! fm.removeItem(at: removedURL)
        try! fm.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private var filesDataPath: URL {
        directory.appending(component: "recents")
    }
    
    init(_ directory: URL, limit: Int = 100) throws {
        guard directory.isFileURL
        else {
            throw Error.invalidURL
        }
        
        let fm = FileManager()
        if !fm.fileExists(atPath: directory.path()) {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        if !directory.isDirectory {
            throw Error.fileAlreadyExists
        }
        self.directory = directory
        self.limit = limit
        
        archive = .empty
        if let data = try? Data(contentsOf: filesDataPath),
           let stored = try? JSONDecoder().decode(Archive.self, from: data) {
            archive = stored
        }
    }

    private func store() {
        let tostore = archive

            do {
                let data = try JSONEncoder().encode(tostore)
                try data.write(to: filesDataPath)
            }
            catch {
                print("Error writing recent files data to \(filesDataPath): \(error.localizedDescription)")
            }
    }
    
    func usingURL(for file: File, callback: @escaping (URL) async throws -> Void) async throws {
        
        guard let url = archive.copiedFiles[file.fileURL] else { return }
        
        try await callback(url)
    }
    
    func usingOriginalURL(for file: File, callback: @escaping (URL) async throws -> Void) async throws {
        guard file.representsFileSystemFile else { return }
        
        try await callback(file.fileURL)
    }

}

// MARK: - Static Constants

@available(macOS 14.0, *)
extension RecentFiles {
    static let slashReplacement = "|||"
    
    @MainActor
    public static let forApp: RecentFiles? = {
        let limit = UserDefaults.standard.recentFileLimit
        return try? RecentFiles(URL.applicationSupportDirectory.appending(component: "RecentFiles"), limit: limit)
    }()
}

// MARK: -

@available(macOS 14.0, *)
extension UserDefaults {
    var recentFileLimitKey: String { #function }
    var recentFileLimit: Int {
        get {
            value(forKey: recentFileLimitKey) as? Int ?? 50
        }
        set {
            set(newValue, forKey: recentFileLimitKey)
        }
    }
}

// MARK: - Image Representations

import AppKit

@available(macOS 14.0, *)
extension RecentFiles.File {
    
    var icon: NSImage {
        NSWorkspace.shared.icon(for: type)
    }
}

import SwiftUI

@available(macOS 14.0, *)
extension RecentFiles {
    
    @ViewBuilder
    func asyncPreview(for file: File, size: CGFloat = 32) -> some View {
        
        if file.type.conforms(to: .image) {
            
            let url = archive.copiedFiles[file.fileURL] ?? file.fileURL
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } placeholder: {
                Image(nsImage: file.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
        else {
            
            // fall back to just showing an icon for the file type,
            // sized as appropriate
            Image(nsImage: file.icon)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
