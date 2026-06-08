import Foundation
import ZIPFoundation

struct EPUBParser {
    func parse(url: URL) throws -> Book {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw BookImportError.unsupportedFormat
        }

        let containerXML = try readText("META-INF/container.xml", in: archive)
        guard let opfPath = containerXML.firstXMLAttribute(named: "full-path") else {
            throw BookImportError.unsupportedFormat
        }

        let opfXML = try readText(opfPath, in: archive)
        let basePath = directoryPath(for: opfPath)
        let title = opfXML.firstXMLTagContent(named: "dc:title")?
            .htmlDecoded
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let author = opfXML.firstXMLTagContent(named: "dc:creator")?.htmlDecoded

        let manifest = parseManifest(opfXML)
        let spineIDs = parseSpineIDs(opfXML)

        var chapters: [BookChapter] = []
        for itemID in spineIDs {
            guard let href = manifest[itemID] else { continue }
            let entryPath = joinedPath(basePath: basePath, href: href)
            guard let html = try? readText(entryPath, in: archive) else { continue }
            let text = html.htmlToPlainText
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let chapterTitle = html.firstHeading ?? "Chapter \(chapters.count + 1)"
            chapters.append(BookChapter(title: chapterTitle, content: text))
        }

        guard !chapters.isEmpty else {
            throw BookImportError.emptyFile
        }

        return Book(
            title: title?.isEmpty == false ? title! : url.deletingPathExtension().lastPathComponent,
            author: author,
            chapters: chapters
        )
    }

    private func readText(_ path: String, in archive: Archive) throws -> String {
        guard let entry = archive[path] else {
            throw BookImportError.unsupportedFormat
        }

        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }

        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16)
            ?? ""
    }

    private func parseManifest(_ xml: String) -> [String: String] {
        let pattern = #"<item\b[^>]*/?>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [:] }
        let nsText = xml as NSString
        var result: [String: String] = [:]

        for match in regex.matches(in: xml, range: NSRange(location: 0, length: nsText.length)) {
            let tag = nsText.substring(with: match.range)
            guard let id = tag.firstXMLAttribute(named: "id"),
                  let href = tag.firstXMLAttribute(named: "href") else {
                continue
            }
            result[id] = href.htmlDecoded
        }

        return result
    }

    private func parseSpineIDs(_ xml: String) -> [String] {
        let pattern = #"<itemref\b[^>]*\bidref\s*=\s*["']([^"']+)["'][^>]*/?>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let nsText = xml as NSString
        return regex.matches(in: xml, range: NSRange(location: 0, length: nsText.length)).compactMap {
            nsText.substring(with: $0.range(at: 1))
        }
    }

    private func joinedPath(basePath: String, href: String) -> String {
        if basePath == "." || basePath == "/" || basePath.isEmpty {
            return href
        }
        return "\(basePath)/\(href)".replacingOccurrences(of: "//", with: "/")
    }

    private func directoryPath(for path: String) -> String {
        let nsPath = path as NSString
        let directory = nsPath.deletingLastPathComponent
        return directory == "." ? "" : directory
    }
}

private extension String {
    func firstXMLAttribute(named name: String) -> String? {
        let pattern = #"\#(name)\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsText = self as NSString
        guard let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: nsText.length)) else { return nil }
        return nsText.substring(with: match.range(at: 1)).htmlDecoded
    }

    func firstXMLTagContent(named name: String) -> String? {
        let pattern = #"<\#(name)[^>]*>(.*?)</\#(name)>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let nsText = self as NSString
        guard let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: nsText.length)) else { return nil }
        return nsText.substring(with: match.range(at: 1))
    }

    var firstHeading: String? {
        let pattern = #"<h[1-3][^>]*>(.*?)</h[1-3]>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let nsText = self as NSString
        guard let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: nsText.length)) else { return nil }
        return nsText.substring(with: match.range(at: 1)).htmlToPlainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var htmlToPlainText: String {
        var value = self
        value = value.replacingOccurrences(of: #"(?is)<style.*?</style>"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?is)<script.*?</script>"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?i)<br\s*/?>"#, with: "\n", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?i)</p>"#, with: "\n\n", options: .regularExpression)
        value = value.replacingOccurrences(of: #"(?s)<[^>]+>"#, with: "", options: .regularExpression)
        value = value.htmlDecoded
        value = value.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var htmlDecoded: String {
        var value = self
        let replacements = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&nbsp;": " "
        ]
        for (from, to) in replacements {
            value = value.replacingOccurrences(of: from, with: to)
        }
        return value
    }
}
