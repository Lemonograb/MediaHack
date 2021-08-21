import Player
import UIKit

final class AppRouter {
    func setup(in window: UIWindow) {
        let root = MainViewController()
        let rootNavigation = UINavigationController(rootViewController: root)
        rootNavigation.setNavigationBarHidden(true, animated: false)

        window.rootViewController = rootNavigation
        window.makeKeyAndVisible()
    }
}
