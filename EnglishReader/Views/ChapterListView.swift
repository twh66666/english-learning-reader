import SwiftUI

struct ChapterListView: View {
    let book: Book
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            List(book.chapters.indices, id: \.self) { index in
                Button {
                    onSelect(index)
                } label: {
                    HStack {
                        Text(book.chapters[index].title)
                            .lineLimit(1)
                        Spacer()
                        if index == selectedIndex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
            .navigationTitle("章节")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
