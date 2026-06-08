import SwiftUI

struct ReaderView: View {
    @EnvironmentObject private var libraryStore: BookLibraryStore
    @EnvironmentObject private var dictionaryService: DictionaryService

    @State private var book: Book
    @State private var settings = ReaderSettings()
    @State private var pages: [String] = []
    @State private var selectedEntry: DictionaryEntry?
    @State private var selectedMissingWord: String?
    @State private var isSettingsPresented = false
    @State private var isChaptersPresented = false
    @StateObject private var volumeController = VolumeButtonPageController()

    init(book: Book) {
        _book = State(initialValue: book)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                settings.theme.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    ReaderPageView(
                        text: currentPageText,
                        settings: settings,
                        onWordTap: handleWordTap
                    )
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .gesture(
                        DragGesture(minimumDistance: 24)
                            .onEnded { value in
                                if value.translation.width < -30 {
                                    nextPage()
                                } else if value.translation.width > 30 {
                                    previousPage()
                                }
                            }
                    )
                    footer
                }
            }
            .onAppear {
                applyBrightness()
                configureVolumeController()
                repaginate(pageSize: pageSize(from: proxy.size))
            }
            .onDisappear {
                volumeController.stop()
            }
            .onChange(of: settings) { _, _ in
                applyBrightness()
                configureVolumeController()
                repaginate(pageSize: pageSize(from: proxy.size))
            }
            .onChange(of: book.progress.chapterIndex) { _, _ in
                repaginate(pageSize: pageSize(from: proxy.size))
            }
            .sheet(isPresented: $isSettingsPresented) {
                ReaderSettingsView(settings: $settings)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $isChaptersPresented) {
                ChapterListView(book: book, selectedIndex: book.progress.chapterIndex) { index in
                    jumpToChapter(index)
                    isChaptersPresented = false
                }
            }
            .sheet(item: $selectedEntry) { entry in
                DictionarySheet(entry: entry)
                    .presentationDetents([.height(260)])
            }
            .alert("未收录", isPresented: Binding(
                get: { selectedMissingWord != nil },
                set: { if !$0 { selectedMissingWord = nil } }
            )) {
                Button("知道了", role: .cancel) { selectedMissingWord = nil }
            } message: {
                Text("离线词典里还没有 “\(selectedMissingWord ?? "")”。")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentChapter: BookChapter? {
        guard book.chapters.indices.contains(book.progress.chapterIndex) else { return nil }
        return book.chapters[book.progress.chapterIndex]
    }

    private var currentPageText: String {
        guard pages.indices.contains(book.progress.pageIndex) else { return currentChapter?.content ?? "" }
        return pages[book.progress.pageIndex]
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                isChaptersPresented = true
            } label: {
                Image(systemName: "list.bullet")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(currentChapter?.title ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "textformat.size")
            }
        }
        .foregroundStyle(settings.theme.textColor)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        HStack {
            Button(action: previousPage) {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .disabled(book.progress.chapterIndex == 0 && book.progress.pageIndex == 0)

            Spacer()

            Text("\(book.progress.pageIndex + 1) / \(max(pages.count, 1))")
                .font(.caption)

            Spacer()

            Button(action: nextPage) {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(isAtBookEnd)
        }
        .foregroundStyle(settings.theme.textColor)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var isAtBookEnd: Bool {
        book.progress.chapterIndex == book.chapters.count - 1 && book.progress.pageIndex >= pages.count - 1
    }

    private func pageSize(from size: CGSize) -> CGSize {
        CGSize(width: max(size.width - 44, 80), height: max(size.height - 150, 120))
    }

    private func repaginate(pageSize: CGSize) {
        let chapterText = currentChapter?.content ?? ""
        pages = ReaderPaginator().paginate(text: chapterText, pageSize: pageSize, settings: settings)
        book.progress.pageIndex = min(book.progress.pageIndex, max(pages.count - 1, 0))
        persistProgress()
    }

    private func nextPage() {
        if book.progress.pageIndex + 1 < pages.count {
            book.progress.pageIndex += 1
        } else if book.progress.chapterIndex + 1 < book.chapters.count {
            book.progress.chapterIndex += 1
            book.progress.pageIndex = 0
        }
        persistProgress()
    }

    private func previousPage() {
        if book.progress.pageIndex > 0 {
            book.progress.pageIndex -= 1
        } else if book.progress.chapterIndex > 0 {
            book.progress.chapterIndex -= 1
            book.progress.pageIndex = 0
        }
        persistProgress()
    }

    private func jumpToChapter(_ index: Int) {
        guard book.chapters.indices.contains(index) else { return }
        book.progress.chapterIndex = index
        book.progress.pageIndex = 0
        persistProgress()
    }

    private func persistProgress() {
        Task {
            await libraryStore.update(book)
        }
    }

    private func handleWordTap(_ word: String) {
        if let entry = dictionaryService.lookup(word) {
            selectedEntry = entry
        } else {
            selectedMissingWord = word
        }
    }

    private func applyBrightness() {
        UIScreen.main.brightness = settings.brightness
    }

    private func configureVolumeController() {
        volumeController.onNextPage = nextPage
        volumeController.onPreviousPage = previousPage
        if settings.volumePagingEnabled {
            volumeController.start()
        } else {
            volumeController.stop()
        }
    }
}
