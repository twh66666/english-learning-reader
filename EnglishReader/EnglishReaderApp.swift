import SwiftUI

@main
struct EnglishReaderApp: App {
    @StateObject private var libraryStore = BookLibraryStore()
    @StateObject private var dictionaryService = DictionaryService()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(libraryStore)
                .environmentObject(dictionaryService)
                .task {
                    await libraryStore.load()
                    await dictionaryService.loadBundledDictionary()
                }
        }
    }
}
