//
//  RecentFilesList.swift
//  Image Reader
//
//  Created by Joseph Wardell on 2/28/25.
//

import SwiftUI
import FileMenuActionsMacOS

@available(macOS 14.0, *)
public struct RecentFilesList: View {
    
    @State private var showingClearAlert = false

    @Environment(\.recentFiles) var recentFiles
    @Environment(\.openDocument) var openDocument
    @Environment(\.showInFinder) var showInFinder

    @ScaledMetric private var labelSpacing = 8
    
    public init() {}
    
    @ViewBuilder
    private func image(for file: RecentFiles.File, size: CGFloat) -> some View {
        if let recentFiles {
            recentFiles.asyncPreview(for: file, size: size)
        }
        else {
            Image(nsImage: file.icon)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
    
    public var body: some View {
        if let files = recentFiles?.files, !files.isEmpty {
            VStack(alignment: .leading) {
                Text("Recent Files")
                    .font(.headline)
                    .padding(.leading)
                                
                List {
                    ForEach(files, id: \.self) { file in
                        
                        Button(action: { open(file) }) {
                            HStack(alignment: .top) {
                                image(for: file, size: 32)
                                
                                VStack(alignment: .leading) {
                                    
                                    Text(file.displayName)
                                    
                                    Text(file.date, format: .dateTime)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    
                                }
                            }
                        }
                        .padding(.bottom, 12)
                        .contextMenu {
                            
                            if file.representsFileSystemFile {
                                Button("Show in Finder") {
                                    show(file)
                                }
                                
                                Divider()
                            }

                            Button("Forget \(file.displayName)") {
                                // don't worry about verifying intention
                                // this is being chosen from a contextual menu
                                // and it's only a recent files list
                                forget(file)
                            }
                        }
                        .buttonStyle(.plain)
                        .listStyle(.plain)
                        .listRowSeparator(.hidden)
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
                
                Button("Forget Recent Files") {
                    showingClearAlert = true
                }
                .font(.footnote)
                .buttonStyle(.plain)
                .padding(.vertical)
                .padding(.leading)
                
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .confirmationDialog("Really Clear Recent Files?", isPresented: $showingClearAlert) {
                Button("Clear Recent Files", role: .destructive) {
                    recentFiles?.clear()
                }
            }
        }
    }

    @MainActor
    private func open(_ file: RecentFiles.File) {
        guard let recentFiles else { return }
        
        openDocument.open(file: file, from: recentFiles)
    }

    @MainActor
    private func forget(_ file: RecentFiles.File) {
            recentFiles?.forget(file)
    }
    
    @MainActor
    private func show(_ file: RecentFiles.File) {
        if let urlToShow = recentFiles?.originalURL(for: file) {
            showInFinder?(url: urlToShow)
        }
//        Task {
//            try await recentFiles?.usingOriginalURL(for: file) { url in
//                await showInFinder?(url: url)
//            }
//        }
    }

    private struct FileListLabel: LabelStyle {
        var spacing: Double = 0.0
        
        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center, spacing: spacing) {
                configuration.icon
                configuration.title
            }
        }
    }

}
