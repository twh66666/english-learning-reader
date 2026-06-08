import Foundation

@MainActor
final class BookLibraryStore: ObservableObject {
    @Published private(set) var books: [Book] = []

    private let fileManager = FileManager.default

    func load() async {
        do {
            let data = try Data(contentsOf: libraryURL)
            books = try JSONDecoder.readerDecoder.decode([Book].self, from: data)
        } catch {
            books = []
        }
    }

    func add(_ book: Book) async {
        books.insert(book, at: 0)
        await save()
    }

    func update(_ book: Book) async {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
        await save()
    }

    func deleteBooks(at offsets: IndexSet) async {
        for index in offsets.sorted(by: >) {
            books.remove(at: index)
        }
        await save()
    }

    private func save() async {
        do {
            try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder.readerEncoder.encode(books)
            try data.write(to: libraryURL, options: [.atomic])
        } catch {
            print("Failed to save library: \(error)")
        }
    }

    private var supportDirectory: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("EnglishReader", isDirectory: true)
    }

    private var libraryURL: URL {
        supportDirectory.appendingPathComponent("library.json")
    }
}

private extension JSONEncoder {
    static var readerEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var readerDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
