import SwiftUI

struct ChapterListView: View {
    let book: Book
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(chapterRows) { row in
                    Button {
                        onSelect(row.index)
                    } label: {
                        HStack {
                            Text(row.title)
                                .lineLimit(1)
                            Spacer()
                            if row.index == selectedIndex {
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

    private var chapterRows: [ChapterRow] {
        book.chapters.enumerated().map { index, chapter in
            ChapterRow(id: chapter.id, index: index, title: chapter.title)
        }
    }
}

private struct ChapterRow: Identifiable {
    let id: UUID
    let index: Int
    let title: String
}
