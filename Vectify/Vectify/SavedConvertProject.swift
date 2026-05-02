import Foundation

/// One named Convert workspace: folders (as bookmarks), engine toggles, and log text.
struct SavedConvertProject: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var inputBookmark: Data?
    var outputBookmark: Data?
    var applySvgo: Bool
    var overwrite: Bool
    var logLines: [String]
}

struct ConvertProjectsDocument: Codable {
    var projects: [SavedConvertProject]
    var activeProjectID: UUID?
}

enum ConvertProjectPersistence {
    private static let appFolderName = "io.avfeaster.vectify"
    private static let fileName = "convert-projects.json"

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent(appFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(fileName)
    }

    static func load() -> ConvertProjectsDocument? {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? JSONDecoder().decode(ConvertProjectsDocument.self, from: Data(contentsOf: url))
    }

    static func save(_ doc: ConvertProjectsDocument) throws {
        let data = try JSONEncoder().encode(doc)
        try data.write(to: fileURL, options: .atomic)
    }
}
