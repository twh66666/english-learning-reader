import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: BookLibraryStore

    @State private var selectedTab = 0
    @State private var isImporterPresented = false
    @State private var importError: String?
    @State private var selectedBook: Book?
    @State private var downloadingBookIDs: Set<Int> = []

    private let importer = BookImportService()
    private let storeProvider = PublicDomainBookStoreProvider()

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                BookshelfTab(
                    books: libraryStore.books,
                    onOpen: { selectedBook = $0 },
                    onDelete: { offsets in
                        Task { await libraryStore.deleteBooks(at: offsets) }
                    }
                )
                .tabItem {
                    Label("书架", systemImage: "books.vertical")
                }
                .tag(0)

                BookStoreTab(
                    downloadingBookIDs: downloadingBookIDs,
                    onDownload: { storeBook in
                        Task { await download(storeBook) }
                    }
                )
                .tabItem {
                    Label("书城", systemImage: "bag")
                }
                .tag(1)
            }
            .navigationTitle(selectedTab == 0 ? "书架" : "书城")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("导入", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.plainText, .text, .epub],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleImport(result)
                }
            }
            .alert("提示", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("知道了", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .navigationDestination(item: $selectedBook) { book in
                ReaderView(book: book)
            }
        }
    }

    @MainActor
    private func handleImport(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let book = try await importer.importBook(from: url)
            await libraryStore.add(book)
            selectedTab = 0
            selectedBook = book
        } catch {
            importError = error.localizedDescription
        }
    }

    @MainActor
    private func download(_ storeBook: StoreBook) async {
        guard !downloadingBookIDs.contains(storeBook.id) else { return }
        downloadingBookIDs.insert(storeBook.id)
        defer { downloadingBookIDs.remove(storeBook.id) }

        do {
            let book = try await storeProvider.download(storeBook)
            await libraryStore.add(book)
            selectedTab = 0
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct BookshelfTab: View {
    let books: [Book]
    let onOpen: (Book) -> Void
    let onDelete: (IndexSet) -> Void

    var body: some View {
        Group {
            if books.isEmpty {
                ContentUnavailableView("暂无书籍", systemImage: "book.closed", description: Text("从书城下载，或导入英文小说 TXT / EPUB 后开始阅读。"))
            } else {
                List {
                    ForEach(books) { book in
                        Button {
                            onOpen(book)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(book.chapters.count) 章")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete(perform: onDelete)
                }
            }
        }
    }
}

private struct BookStoreTab: View {
    let downloadingBookIDs: Set<Int>
    let onDownload: (StoreBook) -> Void

    @State private var query = ""
    @State private var books: [StoreBook] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let provider = PublicDomainBookStoreProvider()

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            if isLoading {
                ProgressView("正在搜索")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if books.isEmpty {
                ContentUnavailableView("搜索英文公共版权书", systemImage: "magnifyingglass", description: Text("输入书名或作者，下载后会自动加入书架。"))
            } else {
                List(books) { book in
                    StoreBookRow(
                        book: book,
                        isDownloading: downloadingBookIDs.contains(book.id),
                        onDownload: { onDownload(book) }
                    )
                }
            }
        }
        .task {
            await search()
        }
        .alert("书城错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            TextField("搜索书名或作者", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit {
                    Task { await search() }
                }

            Button {
                Task { await search() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .frame(width: 38, height: 34)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @MainActor
    private func search() async {
        isLoading = true
        defer { isLoading = false }

        do {
            books = try await provider.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct StoreBookRow: View {
    let book: StoreBook
    let isDownloading: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(book.authorText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Label("\(book.downloadCount)", systemImage: "arrow.down.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    onDownload()
                } label: {
                    if isDownloading {
                        ProgressView()
                    } else {
                        Label("下载", systemImage: "square.and.arrow.down")
                    }
                }
                .disabled(isDownloading || book.bestDownloadURL == nil)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct PublicDomainBookStoreProvider {
    func search(query: String) async throws -> [StoreBook] {
        var components = URLComponents(string: "https://gutendex.com/books/")!
        var items = [
            URLQueryItem(name: "languages", value: "en")
        ]
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "search", value: trimmed))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw BookStoreError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GutendexResponse.self, from: data)
        return response.results
    }

    func download(_ storeBook: StoreBook) async throws -> Book {
        guard let url = storeBook.bestDownloadURL else {
            throw BookStoreError.noDownloadableFormat
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let ext = storeBook.bestDownloadExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("store-\(storeBook.id)-\(UUID().uuidString)")
            .appendingPathExtension(ext)

        try data.write(to: tempURL, options: [.atomic])

        var book: Book
        if ext == "epub" {
            book = try EPUBParser().parse(url: tempURL)
        } else {
            book = try TXTParser().parse(url: tempURL)
        }

        if book.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            book.title = storeBook.title
        }
        if book.author == nil {
            book.author = storeBook.authorText
        }

        try? FileManager.default.removeItem(at: tempURL)
        return book
    }
}

private enum BookStoreError: LocalizedError {
    case invalidURL
    case noDownloadableFormat

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "书城地址无效。"
        case .noDownloadableFormat:
            return "这本书暂时没有可下载的 EPUB 或 TXT 格式。"
        }
    }
}

private struct GutendexResponse: Decodable {
    let results: [StoreBook]
}

private struct StoreBook: Identifiable, Decodable {
    let id: Int
    let title: String
    let authors: [StoreAuthor]
    let formats: [String: String]
    let downloadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authors
        case formats
        case downloadCount = "download_count"
    }

    var authorText: String {
        let names = authors.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "Unknown author" : names.joined(separator: ", ")
    }

    var bestDownloadURL: URL? {
        if let epub = bestEPUBURLString {
            return URL(string: epub)
        }

        if let text = bestTextURLString {
            return URL(string: text)
        }

        return nil
    }

    var bestDownloadExtension: String {
        bestEPUBURLString == nil ? "txt" : "epub"
    }

    private var bestEPUBURLString: String? {
        formats.first(where: { key, value in
            key.contains("application/epub+zip") && value.hasPrefix("https://")
        })?.value
    }

    private var bestTextURLString: String? {
        formats.first(where: { key, value in
            key.contains("text/plain") && value.hasPrefix("https://")
        })?.value
    }
}

private struct StoreAuthor: Decodable {
    let name: String
}
