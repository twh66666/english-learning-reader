import Foundation

struct Book: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var author: String?
    var importedAt: Date
    var chapters: [BookChapter]
    var progress: ReadingProgress

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        importedAt: Date = Date(),
        chapters: [BookChapter],
        progress: ReadingProgress = ReadingProgress()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.importedAt = importedAt
        self.chapters = chapters
        self.progress = progress
    }
}

struct BookChapter: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String

    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}

struct ReadingProgress: Codable, Hashable {
    var chapterIndex: Int
    var pageIndex: Int

    init(chapterIndex: Int = 0, pageIndex: Int = 0) {
        self.chapterIndex = chapterIndex
        self.pageIndex = pageIndex
    }
}
