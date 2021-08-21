import Player
import SharedCode
import SubtitlesOverlay
import UIKit

final class AppRouter {
    func setup(in window: UIWindow) {
        let root: UIViewController
        if Device.isPhone {
            root = SubtitlesOverlayViewController()
        } else {
            root = PlayerViewController()
        }
        let rootNavigation = UINavigationController(rootViewController: root)
        rootNavigation.setNavigationBarHidden(true, animated: false)

        window.rootViewController = rootNavigation
        window.makeKeyAndVisible()
    }
}
