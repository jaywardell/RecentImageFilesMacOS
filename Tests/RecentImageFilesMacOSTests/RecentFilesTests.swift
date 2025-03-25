//
//  RecentFilesTests.swift
//  ImageReaderTests
//
//  Created by Joseph Wardell on 2/27/25.
//

import Foundation
import Testing

@testable import RecentImageFilesMacOS

@Suite("init")
struct RecentFiles_Init {
    
    @available(macOS 14.0, *)
    @Test
    func throws_if_not_given_a_directory() throws {
        #expect(throws: RecentFiles.Error.invalidURL) {
            try RecentFiles(URL(string: "http://www.apple.com")!)
        }
    }
    
    @available(macOS 14.0, *)
    @Test
    func does_not_throw_if_given_fileURL_for_directory() throws {
        let temp = createTemporaryDirectory()
        
        #expect(throws: Never.self) {
            try RecentFiles(temp)
        }
    }

    @available(macOS 14.0, *)
    @Test
    func creates_directory_if_did_not_exist() throws {
        let temp = createTemporaryDirectory()
        
        _ = try RecentFiles(temp)
        
        #expect(FileManager().fileExists(atPath: temp.path()))
        #expect(temp.isDirectory)
    }
    
    @available(macOS 14.0, *)
    @Test
    func throws_if_directory_is_a_file() throws {
        let temp = createTemporaryDirectory()
        
        let fm = FileManager()
        fm.createFile(atPath: temp.path(), contents: Data())
        
        #expect(throws: RecentFiles.Error.fileAlreadyExists) {
            _ = try RecentFiles(temp)
        }
    }
    
    @available(macOS 14.0, *)
    @Test
    func does_not_throw_if_directory_did_exist() async throws {
        let temp = createTemporaryDirectory()
        
        let fm = FileManager()
        try fm.createDirectory(at: temp, withIntermediateDirectories: true)
        
        #expect(throws: Never.self) {
            _ = try RecentFiles(temp)
        }
    }
    
    @available(macOS 14.0, *)
    @Test
    func takes_directory_passed_in() throws {
        let temp = createTemporaryDirectory()
        
        let sut = try RecentFiles(temp)
        
        #expect(sut.directory == temp)
    }
    
    @available(macOS 14.0, *)
    @Test
    func takes_limit_passed_in() throws {
        let temp = createTemporaryDirectory()
        
        let expected = 5
        let sut = try RecentFiles(temp, limit: expected)
        
        #expect(sut.limit == expected)
    }

    @available(macOS 14.0, *)
    @Test
    func stores_recentFiles_across_instances() async throws {
        let temp = createTemporaryDirectory()
        let first = try RecentFiles(temp)

        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))

        let expected = [file1, file2, file3]
        
        // insert them backwards since
        // we want them to appear
        // in rweverse-chronological order
        for file in expected.reversed() {
            try first.add(file)
        }
        #expect(first.files == expected)

        let second = try RecentFiles(temp)
        #expect(second.files == expected)
    }
    
    @available(macOS 14.0, *)
    @Test
    func stores_recentFiles_across_instances_when_cleared() async throws {
        let temp = createTemporaryDirectory()
        let first = try RecentFiles(temp)

        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))

        let files = [file1, file2, file3]
        
        for file in files {
            try first.add(file)
        }
        
        first.clear()
        
        let second = try RecentFiles(temp)
        #expect(second.files.isEmpty)
    }

    @available(macOS 14.0, *)
    @Test
    func stores_recentFiles_across_instances_when_forgotten() async throws {
        let temp = createTemporaryDirectory()
        let first = try RecentFiles(temp)

        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))

        let files = [file1, file2, file3]
        
        for file in files {
            try first.add(file)
        }
        
        first.forget(file2)
        
        let second = try RecentFiles(temp)
        #expect(second.files == first.files)
    }

}



@Suite("default instance for use in the app")
struct forApp {
    
    @MainActor
    @available(macOS 14.0, *)
    @Test
    func testPath() {
        let sut = RecentFiles.forApp
        #expect(sut?.limit == UserDefaults.standard.recentFileLimit)
        #expect(true == sut?.directory.absoluteString.hasSuffix("/Library/Application%20Support/RecentFiles"))
        
    }
}


@Suite("files")
struct files {
    @available(macOS 14.0, *)
    @Test
    func empty_on_init() {
        let sut = makeSUT()
        #expect(sut.files.isEmpty)
    }
}


 



@Suite("add")
struct add {
    
    @available(macOS 14.0, *)
    @Test
    func adds_file_to_files_array() async throws {
        let sut = makeSUT()
        
        let file = try #require(RecentFiles.File(createTemporaryFile()))
        
        try sut.add(file)
        
        #expect(sut.files == [file])
    }
    
    @available(macOS 14.0, *)
    @Test
    func does_not_add_file_if_it_is_already_in_array() async throws {
        let sut = makeSUT()
        
        let file = try #require(RecentFiles.File(createTemporaryFile()))

        try sut.add(file)
        try sut.add(file)

        #expect(sut.files == [file])
    }
    
    @available(macOS 14.0, *)
    @Test
    func lists_files_in_reverse_order_of_insertions() async throws {
        let sut = makeSUT()
        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))
        try sut.add(file1)
        try sut.add(file2)
        try sut.add(file3)

        #expect(sut.files == [file3, file2,  file1])
    }

    @available(macOS 14.0, *)
    @Test
    func moves_file_to_top_of_list_if_it_is_already_included() async throws {
        let sut = makeSUT()
        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))
        try sut.add(file1)
        try sut.add(file2)
        try sut.add(file3)

        try sut.add(file1)

        #expect(sut.files == [file1, file3, file2])
    }
    
    @available(macOS 14.0, *)
    @Test
    func moves_file_to_top_of_list_if_a_previous_file_with_the_same_date_is_already_included() async throws {
        let sut = makeSUT()
        let file1URL = createTemporaryFile()
        let file1 = try #require(RecentFiles.File(file1URL))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))
        try sut.add(file1)
        try sut.add(file2)
        try sut.add(file3)

            let newfile1 = try #require(RecentFiles.File(file1URL, date: file1.date.addingTimeInterval(1)))
        try sut.add(newfile1)

        #expect(sut.files == [newfile1, file3, file2])
        #expect(sut.files.count == 3)
    }

    @available(macOS 14.0, *)
    @Test("when the limit is reached, remove the oldest item and add the new one")
    func respects_limit() async throws {
        let sut = makeSUT(limit: 2)
        
        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))

        try sut.add(file1)
        try sut.add(file2)
        try sut.add(file3)

        let expected = [file3, file2]
        #expect(sut.files == expected)
    }
    
    @available(macOS 14.0, *)
    @Test
    func moves_file_to_front_when_given_file_from_own_directory() async throws {
        let sut = makeSUT()
        let file1 = try #require(RecentFiles.File(createTemporaryFile()))
        let file2 = try #require(RecentFiles.File(createTemporaryFile()))
        let file3 = try #require(RecentFiles.File(createTemporaryFile()))
        try sut.add(file1)
        try sut.add(file2)
        try sut.add(file3)
        var recentFile: RecentFiles.File!
        try await sut.usingURL(for: file1) {
            recentFile = try #require(RecentFiles.File($0))
        }
        
        try sut.add(recentFile)
        
        #expect(sut.files == [file1, file3, file2])
        #expect(sut.files.count == 3)
    }
}

@Suite("forget")
struct forget {
    
    @available(macOS 14.0, *)
    @Test
    func does_nothing_if_file_is_not_in_list() async throws {
        let sut = makeSUT()
        let file = try #require(RecentFiles.File(createTemporaryFile()))

        let otherfilesCount = 3
        for _ in 0 ..< otherfilesCount {
            try sut.add(RecentFiles.File(createTemporaryFile())!)
        }

        sut.forget(file)

        #expect(!sut.files.contains(file))
        #expect(sut.files.count == otherfilesCount)
    }
    
    @available(macOS 14.0, *)
    @Test
    func removes_file_from_files_array() async throws {
        let sut = makeSUT()
        let file = try #require(RecentFiles.File(createTemporaryFile()))
        try sut.add(file)
        
        let otherfilesCount = 3
        for _ in 0 ..< otherfilesCount {
            try sut.add(RecentFiles.File(createTemporaryFile())!)
        }
        
        sut.forget(file)
        
        #expect(!sut.files.contains(file))
        #expect(sut.files.count == otherfilesCount)
    }
}

@Suite("clear")
@MainActor
struct clear {
   
    @available(macOS 14.0, *)
    @Test func removes_any_added_files() async throws {
        let sut = makeSUT()
        
        for _ in 0 ..< sut.limit {
            let file = try #require(RecentFiles.File(createTemporaryFile()))
            try sut.add(file)
        }
        
        sut.clear()
        
        #expect(sut.files.isEmpty)
    }
}

@Suite("usingURL")
struct UsingURL {

    @available(macOS 14.0, *)
    @Test
    func usingURL_does_nothing_if_file_is_not_contained_in_files() async throws {
        let sut = makeSUT()
        let url = createTemporaryFile()
        let file = try #require(RecentFiles.File(url))
        
        var passedInURL: URL?
        try await sut.usingURL(for: file) {
            passedInURL = $0
        }

        #expect(nil == passedInURL)
    }

    @available(macOS 14.0, *)
    @Test
    func usingURL_passes_back_URL_of_copied_file() async throws {
        let sut = makeSUT()
        let url = createTemporaryFile()
        let file = try #require(RecentFiles.File(url))
        try sut.add(file)
        
        var passedInURL: URL?
        try await sut.usingURL(for: file) {
            passedInURL = $0
        }
        
        #expect(true == passedInURL?.absoluteString.hasPrefix(sut.directory.absoluteString))
    }

}

import UniformTypeIdentifiers
@Suite("File")
struct File {
    
    @available(macOS 14.0, *)
    @Test
    func init_returns_nil_if_not_given_file_URL() {
        #expect(nil == RecentFiles.File(URL(string: "http://www.apple.com")!))
    }

    @available(macOS 14.0, *)
    @Test
    func init_returns_nil_if_file_does_not_exist() {
        let (nonexistentFile, _) = temporaryFile()
        
        #expect(nil == RecentFiles.File(nonexistentFile))
    }
    
    // there was a bug where files with spaces (or other url-encoding characters, probably)
    // in their name would not be created because the File.init() would fail
    // this test verifies that that bug is gone
    @available(macOS 14.0, *)
    @Test
    func init_works_if_given_file_with_spaces_in_name() {
        let fileWithSpaces = createTemporaryFile(named: "name with spaces in it")
        
        #expect(nil != RecentFiles.File(fileWithSpaces))
    }

    @available(macOS 14.0, *)
    @Test
    func init_takes_displayName_from_sugegstedName() {
        let expected = "expected file name"
        let sut = RecentFiles.File(createTemporaryFile(), suggestedName: expected)
        #expect(sut?.displayName == expected)
    }

    @available(macOS 14.0, *)
    @Test
    func init_takes_displayName_from_file_URL_if_no_suggested_name_given() {
        let path = createTemporaryFile(suffix: "text")
        let sut = RecentFiles.File(path)
        let expected = path.deletingPathExtension().lastPathComponent
        #expect(sut?.displayName == expected)
    }

    @available(macOS 14.0, *)
    @Test("The type should be calculated based on the URL's extension", arguments: [
        ("jpg", UTType.jpeg),
        ("txt", UTType.plainText),
        ("mp3", UTType.mp3)
    ])
    func init_takes_type_from_URL(_ input: (String, UTType)) {
        
        let sut = RecentFiles.File(createTemporaryFile(suffix: input.0))
        #expect(sut?.type == input.1)
    }
}


// MARK: - Helpers

@available(macOS 14.0, *)
fileprivate func makeSUT(limit: Int = 10) -> RecentFiles {
    let temp = createTemporaryDirectory()

    return try! RecentFiles(temp, limit: limit)
}

fileprivate func createTemporaryDirectory() -> URL {
    FileManager().temporaryDirectory.appending(component: UUID().uuidString)
}

func temporaryFile(
    named name: String = UUID().uuidString,
    suffix: String = "txt") -> (file: URL, directory: URL) {
    let dir = FileManager().temporaryDirectory.appending(path: "Documents/\(UUID().uuidString)")
    
    let out = dir.appending(component: "/\(name).\(suffix)")

    return (out, dir)
}

func createTemporaryFile(
    named name: String = UUID().uuidString,
    suffix: String = "txt",
    content: String = ""
) -> URL {
    
//    let dir = FileManager().temporaryDirectory.appending(path: "Documents/\(UUID().uuidString)")
//    
//    let out = dir.appending(component: "/\(name).\(suffix)")
  
    let (file, dir) = temporaryFile(named: name, suffix: suffix)
    
    do {
        let fm = FileManager()
        
        try fm.createDirectory(atPath: dir.path(), withIntermediateDirectories: true)
                
        try content.write(to: file, atomically: true, encoding: .utf8)
    }
    catch {
        fatalError(error.localizedDescription)
    }
//    var resource = try? out.resourceValues(forKeys: [.typeIdentifierKey]) ?? URLResourceValues()
//    resource?.contentType =
//    out.setResourceValues(URLResourceValues)
    return file
}
