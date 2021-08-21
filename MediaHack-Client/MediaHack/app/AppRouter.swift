import Player
import SubtitlesOverlay
import UIKit

final class AppRouter {
    func setup(in window: UIWindow) {
//        let root = PlayerViewController()
        let root = SubtitlesOverlayViewController()
        let rootNavigation = UINavigationController(rootViewController: root)
        rootNavigation.setNavigationBarHidden(true, animated: false)

        window.rootViewController = rootNavigation
        window.makeKeyAndVisible()
    }
}
