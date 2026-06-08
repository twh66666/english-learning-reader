import SwiftUI
import UIKit

struct ReaderPageView: UIViewRepresentable {
    let text: String
    let settings: ReaderSettings
    let onWordTap: (String) -> Void
    let onBlankTap: () -> Void
    let onPreviousPage: () -> Void
    let onNextPage: () -> Void

    func makeUIView(context: Context) -> ReaderTextPageUIView {
        let view = ReaderTextPageUIView()
        view.backgroundColor = .clear
        view.onWordTap = onWordTap
        view.onBlankTap = onBlankTap
        view.onPreviousPage = onPreviousPage
        view.onNextPage = onNextPage
        return view
    }

    func updateUIView(_ uiView: ReaderTextPageUIView, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = settings.lineSpacing
        paragraph.paragraphSpacing = settings.lineSpacing
        paragraph.lineBreakMode = .byWordWrapping

        uiView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: settings.fontSize),
                .foregroundColor: UIColor(settings.theme.textColor),
                .paragraphStyle: paragraph
            ]
        )
        uiView.onWordTap = onWordTap
        uiView.onBlankTap = onBlankTap
        uiView.onPreviousPage = onPreviousPage
        uiView.onNextPage = onNextPage
    }
}

final class ReaderTextPageUIView: UIView {
    var onWordTap: ((String) -> Void)?
    var onBlankTap: (() -> Void)?
    var onPreviousPage: (() -> Void)?
    var onNextPage: (() -> Void)?

    var attributedText = NSAttributedString(string: "") {
        didSet {
            textStorage.setAttributedString(attributedText)
            setNeedsLayout()
            setNeedsDisplay()
        }
    }

    private let textStorage = NSTextStorage(string: "")
    private let layoutManager = NSLayoutManager()
    private let textContainer = NSTextContainer(size: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureTextKit()
        installGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureTextKit()
        installGestures()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
        layoutManager.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length), actualCharacterRange: nil)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard textStorage.length > 0 else { return }
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
    }

    private func configureTextKit() {
        isOpaque = false
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        layoutManager.usesFontLeading = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
    }

    private func installGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(rightSwipe)
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        guard textStorage.length > 0 else {
            onBlankTap?()
            return
        }

        let glyphIndex = layoutManager.glyphIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceThroughGlyph: nil
        )
        guard glyphIndex < layoutManager.numberOfGlyphs else {
            onBlankTap?()
            return
        }
        let glyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 1),
            in: textContainer
        ).insetBy(dx: -8, dy: -10)

        guard glyphRect.contains(location) else {
            onBlankTap?()
            return
        }

        let charIndex = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard let word = WordTokenizer.word(at: charIndex, in: attributedText.string) else {
            onBlankTap?()
            return
        }
        onWordTap?(word)
    }

    @objc private func handleSwipe(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.direction {
        case .left:
            onNextPage?()
        case .right:
            onPreviousPage?()
        default:
            break
        }
    }
}
