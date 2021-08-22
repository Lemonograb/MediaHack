import SharedCode
import UIKit

final class ToolTipView: BaseView {
    var onWordAdded: (() -> Void)?

    private var shapeLayer: CALayer?
    private let wordLabel = UILabel()
    private let definitionLabel = UILabel()

    private let touchContainer = UIView()
    private let iconImageView = UIImageView(image: UIImage(named: "ic_plus"))

    private let word: String
    private let definition: [String]

    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    var cornerRadius: CGFloat = 4 { didSet { setNeedsDisplay() } }
    var calloutSize: CGFloat = 8 { didSet { setNeedsDisplay() } }
    var fillColor: UIColor = .clear { didSet { setNeedsDisplay() } }
    var strokeColor: UIColor = .clear { didSet { setNeedsDisplay() } }

    init(word: String, definition: [String]) {
        self.word = word
        self.definition = definition
        super.init()
        addSubview(wordLabel)
        addSubview(definitionLabel)
        addSubview(touchContainer)
        touchContainer.addSubview(iconImageView)

        wordLabel.attributedText = word.capitalized.builder
            .font(UIFont.systemFont(ofSize: 13, weight: .medium))
            .foregroundColor(#colorLiteral(red: 0.1960550249, green: 0.1960947812, blue: 0.1960498393, alpha: 1)).result

        wordLabel.pin(.height).const(18).equal()
        wordLabel.pin(.top).to(self).const(8).equal()
        wordLabel.pin(.left).to(self).const(8).equal()

        definitionLabel.pin(.height).const(18).equal()
        definitionLabel.pin(.top).to(wordLabel, .bottom).equal()
        definitionLabel.pin(.left).to(self).const(8).equal()

        touchContainer.pin(.width).const(32).equal()
        touchContainer.pin(.height).const(32).equal()
        touchContainer.pin(.top).to(self).equal()
        touchContainer.pin(.right).to(self).equal()

        iconImageView.pin(.width).const(16).equal()
        iconImageView.pin(.height).const(16).equal()
        iconImageView.pinCenter(to: touchContainer)

        definitionLabel.attributedText = definition[0].capitalized.builder
            .font(UIFont.systemFont(ofSize: 13, weight: .bold))
            .foregroundColor(.white).result

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        touchContainer.addGestureRecognizer(tap)
    }

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

    @objc
    private func handleTap() {
        DefinitionHandler.add(word: word, def: definition)
        onWordAdded?()
    }
}
