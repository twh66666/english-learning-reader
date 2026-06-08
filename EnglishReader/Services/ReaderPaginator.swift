import UIKit

struct ReaderPaginator {
    func paginate(text: String, pageSize: CGSize, settings: ReaderSettings) -> [String] {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, pageSize.width > 20, pageSize.height > 20 else {
            return [cleaned]
        }

        let nsText = cleaned as NSString
        var pages: [String] = []
        var startLocation = 0
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: settings.fontSize),
            .paragraphStyle: paragraphStyle(settings: settings)
        ]

        while startLocation < nsText.length {
            let remainingLength = nsText.length - startLocation
            var low = 1
            var high = remainingLength
            var best = 1

            while low <= high {
                let mid = (low + high) / 2
                let range = NSRange(location: startLocation, length: mid)
                let candidate = nsText.substring(with: range) as NSString
                let rect = candidate.boundingRect(
                    with: pageSize,
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )

                if rect.height <= pageSize.height {
                    best = mid
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }

            let rawEnd = startLocation + best
            let end = adjustedBreak(in: cleaned, nsText: nsText, start: startLocation, proposedEnd: rawEnd)
            let page = nsText.substring(with: NSRange(location: startLocation, length: max(1, end - startLocation)))
            pages.append(page.trimmingCharacters(in: .whitespacesAndNewlines))

            startLocation = max(end, startLocation + 1)
        }

        return pages.isEmpty ? [cleaned] : pages
    }

    private func adjustedBreak(in text: String, nsText: NSString, start: Int, proposedEnd: Int) -> Int {
        guard proposedEnd < nsText.length else { return nsText.length }
        let page = nsText.substring(with: NSRange(location: start, length: proposedEnd - start))

        if let newline = page.range(of: "\n", options: .backwards), page.distance(from: newline.lowerBound, to: page.endIndex) < 120 {
            return start + page.distance(from: page.startIndex, to: newline.upperBound)
        }

        if let space = page.rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards), page.distance(from: space.lowerBound, to: page.endIndex) < 80 {
            return start + page.distance(from: page.startIndex, to: space.upperBound)
        }

        return proposedEnd
    }

    private func paragraphStyle(settings: ReaderSettings) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = settings.lineSpacing
        style.paragraphSpacing = settings.lineSpacing
        return style
    }
}
