import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var libraryStore: BookLibraryStore

    @State private var isImporterPresented = false
    @State private var importError: String?
    @State private var selectedBook: Book?

    private let importer = BookImportService()

    var body: some View {
        NavigationStack {
            Group {
                if libraryStore.books.isEmpty {
                    ContentUnavailableView("暂无书籍", systemImage: "book.closed", description: Text("导入英文小说 TXT 或 EPUB 后开始阅读。"))
                } else {
                    List {
                        ForEach(libraryStore.books) { book in
                            Button {
                                selectedBook = book
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
                        .onDelete { offsets in
                            Task { await libraryStore.deleteBooks(at: offsets) }
                        }
                    }
                }
            }
            .navigationTitle("英文阅读")
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
            .alert("导入失败", isPresented: Binding(
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
            selectedBook = book
        } catch {
            importError = error.localizedDescription
        }
    }
}
