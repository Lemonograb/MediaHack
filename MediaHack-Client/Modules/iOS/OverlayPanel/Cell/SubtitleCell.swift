import SharedCode
import UIKit

final class SubtitleCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let text: NSAttributedString
        let isActive: Bool
    }

    var onWordSelected: ((String) -> Void)?
    private let contentLabel = UILabel()

    override func setup() {
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(contentLabel)
        contentLabel.pinEdgesToSuperView()

        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:)))
        longTap.minimumPressDuration = 0.35
        contentView.addGestureRecognizer(longTap)
    }

    func configure(model: Model) {
        contentLabel.attributedText = model.text
        contentLabel.alpha = model.isActive ? 1 : 0.3
    }

    private var selectedWord: String?
    private var lastTouchLocation: CGPoint?
    private var tooltip: ToolTipView?

    func show(definition: [String]) {
        UIView.animate(withDuration: 0.3) {
            self.tooltip?.removeFromSuperview()
        }
        if let word = selectedWord, let location = lastTouchLocation {
            let tooltip = ToolTipView(word: word, definition: definition)
            contentView.addSubview(tooltip)
            tooltip.bounds.size.width = 228
            tooltip.bounds.size.height = 64
            tooltip.cornerRadius = 6
            tooltip.fillColor = #colorLiteral(red: 1, green: 0.6687215567, blue: 0, alpha: 1)
            tooltip.strokeColor = .clear
            tooltip.lineWidth = 0
            tooltip.backgroundColor = .clear
            tooltip.layoutIfNeeded()
            tooltip.alpha = 0
            tooltip.frame.origin.x = location.x - (tooltip.bounds.size.width / 2)
            tooltip.frame.origin.y = location.y - tooltip.bounds.height
            UIView.animate(withDuration: 0.3) {
                tooltip.alpha = 1
            }
            tooltip.onWordAdded = { [unowned self] in
                self.removeDefinition()
            }
            self.tooltip = tooltip
        }
    }

    func removeDefinition() -> Bool {
        guard let view = tooltip else {
            return false
        }
        UIView.animate(withDuration: 0.3) {
            view.removeFromSuperview()
        }
        selectedWord = nil
        lastTouchLocation = nil
        return true
    }

    @objc
    private func handleLongTap(_ r: UILongPressGestureRecognizer) {
        guard let chIndex = r.tappedCharacterIndex(label: contentLabel), r.state == .began else {
            return
        }
        lastTouchLocation = r.location(in: contentView)

        let plain = contentLabel.attributedText.unsafelyUnwrapped.string
        var lowerBoundIndex = plain.index(plain.startIndex, offsetBy: chIndex)
        var upperBoundIndex = plain.index(plain.startIndex, offsetBy: chIndex)

        let indices = plain.indices
        var allowedSet = CharacterSet.letters
        allowedSet.formUnion(CharacterSet(charactersIn: "'"))

        for idx in plain.indices[indices.startIndex ..< lowerBoundIndex].reversed() {
            if CharacterSet(charactersIn: String(plain[idx])).isSubset(of: allowedSet) {
                lowerBoundIndex = idx
            } else {
                break
            }
        }
        for idx in plain.indices[upperBoundIndex ..< indices.endIndex] {
            if CharacterSet(charactersIn: String(plain[idx])).isSubset(of: allowedSet) {
                upperBoundIndex = idx
            } else {
                break
            }
        }
        let str = String(plain[lowerBoundIndex ... upperBoundIndex])
        selectedWord = str
        onWordSelected?(str)
    }
}

extension UILongPressGestureRecognizer {
    func tappedCharacterIndex(label: UILabel) -> Int? {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText.unsafelyUnwrapped)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)

        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        if !textBoundingBox.contains(locationOfTouchInTextContainer) {
            return nil
        }

        return layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}
