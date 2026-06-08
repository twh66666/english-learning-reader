import Foundation

enum WordTokenizer {
    static func normalize(_ word: String) -> String {
        word.lowercased()
            .trimmingCharacters(in: CharacterSet.letters.inverted)
    }

    static func word(at index: Int, in text: String) -> String? {
        let nsText = text as NSString
        guard index >= 0, index < nsText.length else { return nil }

        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: "'-"))
        var start = index
        var end = index

        while start > 0 {
            let scalar = UnicodeScalar(nsText.character(at: start - 1))!
            if !allowed.contains(scalar) { break }
            start -= 1
        }

        while end < nsText.length {
            let scalar = UnicodeScalar(nsText.character(at: end))!
            if !allowed.contains(scalar) { break }
            end += 1
        }

        guard end > start else { return nil }
        let word = nsText.substring(with: NSRange(location: start, length: end - start))
        let normalized = normalize(word)
        return normalized.isEmpty ? nil : normalized
    }
}
