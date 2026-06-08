import SwiftUI

struct ChapterListView: View {
    let book: Book
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(book.chapters.enumerated()), id: \.element.id) { index, chapter in
                Button {
                    onSelect(index)
                } label: {
                    HStack {
                        Text(chapter.title)
                            .lineLimit(1)
                        Spacer()
                        if index == selectedIndex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accent)
                        }
                    }
                }
                }
            }
            .navigationTitle("章节")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
