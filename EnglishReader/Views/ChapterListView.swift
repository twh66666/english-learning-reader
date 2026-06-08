import SwiftUI

struct ChapterListView: View {
    let book: Book
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<book.chapters.count, id: \.self) { index in
                    ChapterRowButton(
                        index: index,
                        title: book.chapters[index].title,
                        isSelected: index == selectedIndex,
                        onSelect: onSelect
                    )
                }
            }
            .navigationTitle("章节")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ChapterRowButton: View {
    let index: Int
    let title: String
    let isSelected: Bool
    let onSelect: (Int) -> Void

    var body: some View {
        Button {
            onSelect(index)
        } label: {
            HStack {
                Text(title)
                    .lineLimit(1)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.accent)
                }
            }
        }
    }
}
