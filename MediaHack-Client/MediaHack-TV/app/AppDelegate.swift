import Networking
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let router = AppRouter()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let newWindow = UIWindow(frame: UIScreen.main.bounds)
        router.setup(in: newWindow)
        window = newWindow
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        WSManager.shared.cancel()
    }
}
