import SwiftUI

struct ReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var libraryStore: BookLibraryStore
    @EnvironmentObject private var dictionaryService: DictionaryService

    @State private var book: Book
    @State private var settings = ReaderSettings()
    @State private var pages: [String] = []
    @State private var selectedEntry: DictionaryEntry?
    @State private var selectedMissingWord: String?
    @State private var isControlsVisible = false
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

                ReaderPageView(
                    text: currentPageText,
                    settings: settings,
                    onWordTap: handleWordTap,
                    onBlankTap: toggleControls,
                    onPreviousPage: previousPage,
                    onNextPage: nextPage
                )
                .frame(width: pageSize(from: proxy).width, height: pageSize(from: proxy).height, alignment: .topLeading)
                .position(x: proxy.size.width / 2, y: pageTopInset(from: proxy) + pageSize(from: proxy).height / 2)

                if isControlsVisible {
                    VStack(spacing: 0) {
                        topBar
                        Spacer()
                        bottomSettingsBar
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: isControlsVisible)
            .onAppear {
                applyBrightness()
                configureVolumeController()
                repaginate(pageSize: pageSize(from: proxy))
            }
            .onDisappear {
                volumeController.stop()
            }
            .onChange(of: settings) { _, _ in
                applyBrightness()
                configureVolumeController()
                repaginate(pageSize: pageSize(from: proxy))
            }
            .onChange(of: book.progress.chapterIndex) { _, _ in
                repaginate(pageSize: pageSize(from: proxy))
            }
            .sheet(isPresented: $isChaptersPresented) {
                ChapterListView(book: book, selectedIndex: book.progress.chapterIndex) { index in
                    jumpToChapter(index)
                    isChaptersPresented = false
                }
            }
            .sheet(item: $selectedEntry) { entry in
                DictionarySheet(entry: entry)
                    .presentationDetents([.height(320)])
            }
            .alert("未收录", isPresented: Binding(
                get: { selectedMissingWord != nil },
                set: { if !$0 { selectedMissingWord = nil } }
            )) {
                Button("知道了", role: .cancel) { selectedMissingWord = nil }
            } message: {
                Text("离线词典里暂时没有 “\(selectedMissingWord ?? "")”。")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentChapter: BookChapter? {
        guard book.chapters.indices.contains(book.progress.chapterIndex) else { return nil }
        return book.chapters[book.progress.chapterIndex]
    }

    private var currentPageText: String {
        guard pages.indices.contains(book.progress.pageIndex) else { return "" }
        return pages[book.progress.pageIndex]
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 40, height: 40)
            }

            Button {
                isChaptersPresented = true
            } label: {
                Image(systemName: "list.bullet")
                    .frame(width: 40, height: 40)
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
        }
        .foregroundStyle(settings.theme.textColor)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(settings.theme.backgroundColor.opacity(0.95))
    }

    private var bottomSettingsBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: previousPage) {
                    Image(systemName: "chevron.left")
                        .frame(width: 42, height: 38)
                }
                .disabled(book.progress.chapterIndex == 0 && book.progress.pageIndex == 0)

                Button {
                    isChaptersPresented = true
                } label: {
                    Label("章节", systemImage: "list.bullet")
                        .font(.subheadline)
                }

                Spacer()

                Text("\(book.progress.pageIndex + 1) / \(max(pages.count, 1))")
                    .font(.caption)
                    .monospacedDigit()

                Spacer()

                Button(action: nextPage) {
                    Image(systemName: "chevron.right")
                        .frame(width: 42, height: 38)
                }
                .disabled(isAtBookEnd)
            }

            HStack(spacing: 14) {
                Button {
                    settings.fontSize = max(14, settings.fontSize - 1)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                        .frame(width: 36, height: 34)
                }

                Text("\(Int(settings.fontSize))")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 28)

                Button {
                    settings.fontSize = min(34, settings.fontSize + 1)
                } label: {
                    Image(systemName: "textformat.size.larger")
                        .frame(width: 36, height: 34)
                }

                Spacer()

                ForEach(ReaderTheme.allCases) { theme in
                    Button {
                        settings.theme = theme
                    } label: {
                        Circle()
                            .fill(theme.backgroundColor)
                            .overlay(
                                Circle().stroke(
                                    settings.theme == theme ? settings.theme.textColor : Color.gray.opacity(0.35),
                                    lineWidth: settings.theme == theme ? 2 : 1
                                )
                            )
                            .frame(width: 28, height: 28)
                    }
                    .accessibilityLabel(theme.title)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "sun.min")
                Slider(value: $settings.brightness, in: 0.05...1.0, step: 0.01)
                Image(systemName: "sun.max")

                Toggle(isOn: $settings.volumePagingEnabled) {
                    Image(systemName: "speaker.wave.2")
                }
                .labelsHidden()
                .frame(width: 54)
            }
        }
        .foregroundStyle(settings.theme.textColor)
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(settings.theme.backgroundColor.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.black.opacity(settings.theme == .dark ? 0.35 : 0.12))
                .frame(height: 0.5)
        }
    }

    private var isAtBookEnd: Bool {
        book.progress.chapterIndex == book.chapters.count - 1 && book.progress.pageIndex >= pages.count - 1
    }

    private func pageSize(from proxy: GeometryProxy) -> CGSize {
        let width = proxy.size.width - 40
        let height = proxy.size.height - pageTopInset(from: proxy) - pageBottomInset(from: proxy)
        return CGSize(width: max(width, 80), height: max(height, 120))
    }

    private func pageTopInset(from proxy: GeometryProxy) -> CGFloat {
        proxy.safeAreaInsets.top + 5
    }

    private func pageBottomInset(from proxy: GeometryProxy) -> CGFloat {
        proxy.safeAreaInsets.bottom + 5
    }

    private func repaginate(pageSize: CGSize) {
        let previousPage = book.progress.pageIndex
        let chapterText = currentChapter?.content ?? ""
        pages = ReaderPaginator().paginate(text: chapterText, pageSize: pageSize, settings: settings)
        book.progress.pageIndex = min(previousPage, max(pages.count - 1, 0))
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
            repaginateToLastPageOfCurrentChapter()
        }
        persistProgress()
    }

    private func repaginateToLastPageOfCurrentChapter() {
        let chapterText = currentChapter?.content ?? ""
        let fallbackSize = CGSize(width: UIScreen.main.bounds.width - 40, height: UIScreen.main.bounds.height - 96)
        pages = ReaderPaginator().paginate(text: chapterText, pageSize: fallbackSize, settings: settings)
        book.progress.pageIndex = max(pages.count - 1, 0)
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

    private func toggleControls() {
        isControlsVisible.toggle()
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
