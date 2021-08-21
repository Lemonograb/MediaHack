import SharedCode
import UIKit

final class SubtitlesView: BaseView {
    struct Model {
        let onWordSelected: (String) -> Void
    }

    var text: NSAttributedString? {
        get { return contentLabel.attributedText }
        set { contentLabel.attributedText = newValue }
    }

    private var definitionView: UIView?
    private let contentLabel = UILabel()
    private let model: Model

    init(model: Model) {
        self.model = model
        super.init(frame: .zero)
    }

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
        model.onWordSelected(str)

        definitionView?.removeFromSuperview()
        let tooltip = makeDefinitionView()
        addSubview(tooltip)
        tooltip.frame.origin.x = r.location(in: self).x - (tooltip.bounds.size.width / 2)
        tooltip.frame.origin.y = -tooltip.bounds.height
        definitionView = tooltip
    }

    private func makeDefinitionView() -> UIView {
        let tooltip = ToolTipView()
        tooltip.bounds.size.width = 228
        tooltip.bounds.size.height = 64
        tooltip.cornerRadius = 6
        tooltip.fillColor = #colorLiteral(red: 1, green: 0.6687215567, blue: 0, alpha: 1).withAlphaComponent(0.96)
        tooltip.strokeColor = .clear
        tooltip.lineWidth = 0
        tooltip.backgroundColor = .clear
        return tooltip
    }
}

private final class ToolTipView: BaseView {
    private var shapeLayer: CALayer?

    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    var cornerRadius: CGFloat = 4 { didSet { setNeedsDisplay() } }
    var calloutSize: CGFloat = 8 { didSet { setNeedsDisplay() } }
    var fillColor: UIColor = .clear { didSet { setNeedsDisplay() } }
    var strokeColor: UIColor = .clear { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = UIBezierPath()

        // lower left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - calloutSize))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - calloutSize - cornerRadius),
            controlPoint: CGPoint(x: rect.minX, y: rect.maxY - calloutSize)
        )

        // left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        // upper left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            controlPoint: CGPoint(x: rect.minX, y: rect.minY)
        )

        // top
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))

        // upper right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            controlPoint: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize - cornerRadius))

        // lower right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - calloutSize),
            controlPoint: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize)
        )

        // bottom (including callout)
        path.addLine(to: CGPoint(x: rect.midX + calloutSize, y: rect.maxY - calloutSize))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - calloutSize, y: rect.maxY - calloutSize))
        path.close()

        fillColor.setFill()
        path.fill()

        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
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

        return layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

public extension UIView {
    enum PeakSide: Int {
        case Top
        case Left
        case Right
        case Bottom
    }

    func addPikeOnView(side: PeakSide, size: CGFloat = 10.0) -> CALayer {
        layoutIfNeeded()
        let peakLayer = CAShapeLayer()
        var path: CGPath?
        switch side {
        case .Top:
            path = makePeakPathWithRect(rect: bounds, topSize: size, rightSize: 0.0, bottomSize: 0.0, leftSize: 0.0)
        case .Left:
            path = makePeakPathWithRect(rect: bounds, topSize: 0.0, rightSize: 0.0, bottomSize: 0.0, leftSize: size)
        case .Right:
            path = makePeakPathWithRect(rect: bounds, topSize: 0.0, rightSize: size, bottomSize: 0.0, leftSize: 0.0)
        case .Bottom:
            path = makePeakPathWithRect(rect: bounds, topSize: 0.0, rightSize: 0.0, bottomSize: size, leftSize: 0.0)
        }
        peakLayer.path = path
        let color = (backgroundColor?.cgColor)
        peakLayer.fillColor = color
        peakLayer.strokeColor = color
        peakLayer.lineWidth = 1
        peakLayer.position = CGPoint.zero
        layer.insertSublayer(peakLayer, at: 0)

        return layer
    }

    func makePeakPathWithRect(rect: CGRect, topSize ts: CGFloat, rightSize rs: CGFloat, bottomSize bs: CGFloat, leftSize ls: CGFloat) -> CGPath {
        //                      P3
        //                    /    \
        //      P1 -------- P2     P4 -------- P5
        //      |                               |
        //      |                               |
        //      P16                            P6
        //     /                                 \
        //  P15                                   P7
        //     \                                 /
        //      P14                            P8
        //      |                               |
        //      |                               |
        //      P13 ------ P12    P10 -------- P9
        //                    \   /
        //                     P11

        let centerX = rect.width / 2
        let centerY = rect.height / 2
        var h: CGFloat = 0
        let path = CGMutablePath()
        var points: [CGPoint] = []
        // P1
        points.append(CGPoint(x: rect.origin.x, y: rect.origin.y))
        // Points for top side
        if ts > 0 {
            h = ts * sqrt(3.0) / 2
            let x = rect.origin.x + centerX
            let y = rect.origin.y
            points.append(CGPoint(x: x - ts, y: y))
            points.append(CGPoint(x: x, y: y - h))
            points.append(CGPoint(x: x + ts, y: y))
        }

        // P5
        points.append(CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y))
        // Points for right side
        if rs > 0 {
            h = rs * sqrt(3.0) / 2
            let x = rect.origin.x + rect.width
            let y = rect.origin.y + centerY
            points.append(CGPoint(x: x, y: y - rs))
            points.append(CGPoint(x: x + h, y: y))
            points.append(CGPoint(x: x, y: y + rs))
        }

        // P9
        points.append(CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        // Point for bottom side
        if bs > 0 {
            h = bs * sqrt(3.0) / 2
            let x = rect.origin.x + centerX
            let y = rect.origin.y + rect.height
            points.append(CGPoint(x: x + bs, y: y))
            points.append(CGPoint(x: x, y: y + h))
            points.append(CGPoint(x: x - bs, y: y))
        }

        // P13
        points.append(CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
        // Point for left sidey:
        if ls > 0 {
            h = ls * sqrt(3.0) / 2
            let x = rect.origin.x
            let y = rect.origin.y + centerY
            points.append(CGPoint(x: x, y: y + ls))
            points.append(CGPoint(x: x - h, y: y))
            points.append(CGPoint(x: x, y: y - ls))
        }

        let startPoint = points.removeFirst()
        startPath(path: path, onPoint: startPoint)
        for point in points {
            addPoint(point: point, toPath: path)
        }
        addPoint(point: startPoint, toPath: path)
        return path
    }

    private func startPath(path: CGMutablePath, onPoint point: CGPoint) {
        path.move(to: CGPoint(x: point.x, y: point.y))
    }

    private func addPoint(point: CGPoint, toPath path: CGMutablePath) {
        path.addLine(to: CGPoint(x: point.x, y: point.y))
    }
}

// https://stackoverflow.com/questions/1256887/create-tap-able-links-in-the-nsattributedstring-of-a-uilabel
// https://stackoverflow.com/questions/37781165/how-to-convert-character-index-from-layoutmanager-to-string-scale-in-swift
