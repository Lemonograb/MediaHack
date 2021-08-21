import SharedCode
import UIKit

final class SubtitlesView: BaseView {
    var text: NSAttributedString? {
        get { return contentLabel.attributedText }
        set { contentLabel.attributedText = newValue }
    }

    private let contentLabel = UILabel()
    private var textForTextContainer: NSAttributedString?
    private var layoutManager: NSLayoutManager?

    override func setup() {
        contentLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        contentLabel.textColor = .label
        layer.cornerRadius = 4
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping

        backgroundColor = #colorLiteral(red: 0.195160985, green: 0.2001810074, blue: 0.2427157164, alpha: 1).withAlphaComponent(0.85)
        addSubview(contentLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    func setupLayout() {
        let insets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        contentLabel.pinToSuperView(.top).const(insets.top).equal()
        contentLabel.pinToSuperView(.left).const(insets.left).equal()
        contentLabel.pinToSuperView(.bottom).const(-insets.bottom).equal()
        contentLabel.pinToSuperView(.right).const(-insets.right).equal()
    }

    @objc
    private func handleTap(_ r: UITapGestureRecognizer) {
        guard let chIndex = r.tappedCharacterIndex(label: contentLabel) else {
            return
        }
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
        print(str)
    }
}

extension UILabel {
    var layoutManager: NSLayoutManager {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: attributedText!)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.size = bounds.size

        return layoutManager
    }
}

extension UITapGestureRecognizer {
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

        if false {
            let x = UIView()
            let sz: CGFloat = 8
            x.layer.cornerRadius = 4
            x.frame.size.width = sz
            x.frame.size.height = sz
            x.frame.origin = location(in: label.superview)
            x.backgroundColor = UIColor.red.withAlphaComponent(0.35)
            view?.addSubview(x)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                x.removeFromSuperview()
            }
        }

        // let glyphIndex = layoutManager.glyphIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceThroughGlyph: nil)
        return layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

// https://stackoverflow.com/questions/1256887/create-tap-able-links-in-the-nsattributedstring-of-a-uilabel
// https://stackoverflow.com/questions/37781165/how-to-convert-character-index-from-layoutmanager-to-string-scale-in-swift
