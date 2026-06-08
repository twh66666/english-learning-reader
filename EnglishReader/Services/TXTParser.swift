import Foundation

struct TXTParser {
    func parse(url: URL) throws -> Book {
        let data = try Data(contentsOf: url)
        guard let text = decode(data: data), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BookImportError.emptyFile
        }

        let title = url.deletingPathExtension().lastPathComponent
        return Book(title: title, chapters: splitIntoChapters(text))
    }

    private func decode(data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        if let utf16 = String(data: data, encoding: .utf16) {
            return utf16
        }
        let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        return String(data: data, encoding: gb18030)
    }

    private func splitIntoChapters(_ text: String) -> [BookChapter] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let pattern = #"(?m)^\s*(Chapter\s+\d+|CHAPTER\s+\d+|第[一二三四五六七八九十百千万\d]+章).*$"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [BookChapter(title: "正文", content: normalized)]
        }

        let nsText = normalized as NSString
        let matches = regex.matches(in: normalized, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return [BookChapter(title: "正文", content: normalized)]
        }

        var chapters: [BookChapter] = []
        for index in matches.indices {
            let match = matches[index]
            let title = nsText.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            let start = match.range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : nsText.length
            let range = NSRange(location: start, length: end - start)
            let content = nsText.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            chapters.append(BookChapter(title: title, content: content))
        }

        return chapters
    }
}
