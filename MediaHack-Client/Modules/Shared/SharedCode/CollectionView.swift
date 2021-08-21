import UIKit

public protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

public extension ReuseIdentifiable {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

public protocol Configurable {
    associatedtype Model
    func configure(model: Model)
}
