import SwiftUI
import UIKit

struct ReaderPageView: UIViewRepresentable {
    let text: String
    let settings: ReaderSettings
    let onWordTap: (String) -> Void
    let onBlankTap: () -> Void
    let onPreviousPage: () -> Void
    let onNextPage: () -> Void

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
        textView.onPreviousPage = onPreviousPage
        textView.onNextPage = onNextPage
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
        uiView.onWordTap = onWordTap
        uiView.onBlankTap = onBlankTap
        uiView.onPreviousPage = onPreviousPage
        uiView.onNextPage = onNextPage
    }
}

final class TappableTextView: UITextView {
    var onWordTap: ((String) -> Void)?
    var onBlankTap: (() -> Void)?
    var onPreviousPage: (() -> Void)?
    var onNextPage: (() -> Void)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        installGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installGestures()
    }

    private func installGestures() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(_:))))
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(rightSwipe)
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
