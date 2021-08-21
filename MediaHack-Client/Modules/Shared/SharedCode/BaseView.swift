import UIKit

open class BaseView: UIView {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        return nil
    }

    public init() {
        super.init(frame: .zero)
        setup()
    }

    open func setup() {}
}
