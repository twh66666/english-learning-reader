import Foundation

@MainActor
final class DictionaryService: ObservableObject {
    @Published private(set) var isLoaded = false

    private var entries: [String: DictionaryEntry] = [:]

    func loadBundledDictionary() async {
        guard let url = Bundle.main.url(forResource: "dictionary_seed", withExtension: "json") else {
            isLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([DictionaryEntry].self, from: data)
            entries = Dictionary(uniqueKeysWithValues: decoded.map { ($0.word.lowercased(), $0) })
        } catch {
            print("Failed to load dictionary: \(error)")
        }

        isLoaded = true
    }

    func lookup(_ rawWord: String) -> DictionaryEntry? {
        let normalized = WordTokenizer.normalize(rawWord)
        guard !normalized.isEmpty else { return nil }

        if let direct = entries[normalized] {
            return direct
        }

        for candidate in lemmaCandidates(for: normalized) {
            if let entry = entries[candidate] {
                return entry
            }
        }

        return nil
    }

    private func lemmaCandidates(for word: String) -> [String] {
        var candidates: [String] = []

        if word.hasSuffix("ies"), word.count > 3 {
            candidates.append(String(word.dropLast(3)) + "y")
        }
        if word.hasSuffix("es"), word.count > 2 {
            candidates.append(String(word.dropLast(2)))
        }
        if word.hasSuffix("s"), word.count > 1 {
            candidates.append(String(word.dropLast()))
        }
        if word.hasSuffix("ing"), word.count > 4 {
            candidates.append(String(word.dropLast(3)))
            candidates.append(String(word.dropLast(3)) + "e")
        }
        if word.hasSuffix("ed"), word.count > 3 {
            candidates.append(String(word.dropLast(2)))
            candidates.append(String(word.dropLast(1)))
        }

        return candidates
    }
}
