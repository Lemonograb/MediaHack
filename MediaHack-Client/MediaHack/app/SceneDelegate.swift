import UIKit
import Networking

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let appRouter = AppRouter()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = (scene as? UIWindowScene) else { return }
        let window = UIWindow(frame: ws.coordinateSpace.bounds)
        self.window = window
        window.windowScene = ws

        appRouter.setup(in: window)
    }
}
