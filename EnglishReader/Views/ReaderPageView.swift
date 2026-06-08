import SwiftUI
import UIKit

struct ReaderPageView: UIViewRepresentable {
    let text: String
    let settings: ReaderSettings
    let onWordTap: (String) -> Void
    let onBlankTap: () -> Void

    func makeUIView(context: Context) -> TappableTextView {
        let textView = TappableTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.onWordTap = onWordTap
        textView.onBlankTap = onBlankTap
        return textView
    }

    func updateUIView(_ uiView: TappableTextView, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = settings.lineSpacing
        paragraph.paragraphSpacing = settings.lineSpacing

        uiView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: settings.fontSize),
                .foregroundColor: UIColor(settings.theme.textColor),
                .paragraphStyle: paragraph
            ]
        )
    }
}

final class TappableTextView: UITextView {
    var onWordTap: ((String) -> Void)?
    var onBlankTap: (() -> Void)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        guard let position = closestPosition(to: location) else { return }
        let index = offset(from: beginningOfDocument, to: position)
        guard let word = WordTokenizer.word(at: index, in: text) else {
            onBlankTap?()
            return
        }
        onWordTap?(word)
    }
}
