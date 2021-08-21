import UIKit

open class BaseViewController: UIViewController {
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        return nil
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    open func setup() {}
}
