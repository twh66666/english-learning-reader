import UIKit

struct ReaderPaginator {
    func paginate(text: String, pageSize: CGSize, settings: ReaderSettings) -> [String] {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, pageSize.width > 20, pageSize.height > 20 else {
            return [cleaned]
        }

        let nsText = cleaned as NSString
        let safePageSize = CGSize(width: pageSize.width, height: max(pageSize.height - 20, 80))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: settings.fontSize),
            .paragraphStyle: paragraphStyle(settings: settings)
        ]

        var pages: [String] = []
        var start = 0

        while start < nsText.length {
            let proposedLength = fittingLength(
                in: nsText,
                start: start,
                pageSize: safePageSize,
                attributes: attributes
            )
            let proposedEnd = min(start + proposedLength, nsText.length)
            let end = adjustedBreak(nsText: nsText, start: start, proposedEnd: proposedEnd)
            let length = max(1, end - start)
            let page = nsText.substring(with: NSRange(location: start, length: length))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !page.isEmpty {
                pages.append(page)
            }
            start = max(start + length, start + 1)
        }

        return pages.isEmpty ? [cleaned] : pages
    }

    private func fittingLength(
        in nsText: NSString,
        start: Int,
        pageSize: CGSize,
        attributes: [NSAttributedString.Key: Any]
    ) -> Int {
        let remaining = nsText.substring(from: start)
        let storage = NSTextStorage(string: remaining, attributes: attributes)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: pageSize)

        container.lineFragmentPadding = 0
        container.lineBreakMode = .byWordWrapping
        container.maximumNumberOfLines = 0
        layoutManager.usesFontLeading = true
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: container)

        let glyphRange = layoutManager.glyphRange(for: container)
        guard glyphRange.length > 0 else {
            return min(1, nsText.length - start)
        }

        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        return max(1, min(characterRange.length, nsText.length - start))
    }

    private func adjustedBreak(nsText: NSString, start: Int, proposedEnd: Int) -> Int {
        guard proposedEnd < nsText.length else { return nsText.length }
        let length = proposedEnd - start
        guard length > 1 else { return proposedEnd }

        let page = nsText.substring(with: NSRange(location: start, length: length))
        if let newline = page.range(of: "\n", options: .backwards),
           page.distance(from: newline.lowerBound, to: page.endIndex) < 120 {
            return start + page.distance(from: page.startIndex, to: newline.upperBound)
        }

        if let space = page.rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards),
           page.distance(from: space.lowerBound, to: page.endIndex) < 80 {
            return start + page.distance(from: page.startIndex, to: space.upperBound)
        }

        return proposedEnd
    }

    private func paragraphStyle(settings: ReaderSettings) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = settings.lineSpacing
        style.paragraphSpacing = settings.lineSpacing
        style.lineBreakMode = .byWordWrapping
        return style
    }
}
