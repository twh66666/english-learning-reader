import SwiftUI

struct DictionarySheet: View {
    let entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.word)
                    .font(.title2.bold())
                if let phonetic = entry.phonetic, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(entry.translation)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let definition = entry.definition, !definition.isEmpty {
                Divider()
                Text(definition)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(22)
    }
}
