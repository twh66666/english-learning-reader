import Foundation
import UniformTypeIdentifiers

enum BookImportError: LocalizedError {
    case unsupportedFormat
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat: return "暂不支持这种文件格式。"
        case .emptyFile: return "文件内容为空。"
        }
    }
}

struct BookImportService {
    func importBook(from url: URL) async throws -> Book {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let ext = url.pathExtension.lowercased()
        if ext == "txt" {
            return try TXTParser().parse(url: url)
        }
        if ext == "epub" {
            return try EPUBParser().parse(url: url)
        }
        throw BookImportError.unsupportedFormat
    }
}

extension UTType {
    static let epub = UTType(filenameExtension: "epub") ?? .data
}
