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

    private let contentLabel = UILabel()
    private let model: Model

    init(model: Model) {
        self.model = model
        super.init(frame: .zero)
    }

    override func setup() {
        contentLabel.font = UIFont.systemFont(ofSize: 20)
        contentLabel.textColor = .label
        layer.cornerRadius = 4
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping

        backgroundColor = #colorLiteral(red: 0.195160985, green: 0.2001810074, blue: 0.2427157164, alpha: 1).withAlphaComponent(0.85)
        addSubview(contentLabel)
    }

    func setupLayout() {
        let insets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        contentLabel.pinToSuperView(.top).const(insets.top).equal()
        contentLabel.pinToSuperView(.left).const(insets.left).equal()
        contentLabel.pinToSuperView(.bottom).const(-insets.bottom).equal()
        contentLabel.pinToSuperView(.right).const(-insets.right).equal()
    }
}
