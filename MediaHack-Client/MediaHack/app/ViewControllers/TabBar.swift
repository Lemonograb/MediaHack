//
//  TabBar.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 22.08.2021.
//

import OverlayPanel_iOS
import UIKit
import SharedCode

class NavigationMenuBaseController: UITabBarController {
    var tabBarHeight: CGFloat = 96.0
    let tabBarView = UIImageView(image: .init(named: "tabBarFrame"))
    private unowned var overlayVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadTabBar()
    }

    func loadTabBar() {
        let mainNav = UINavigationController(rootViewController: MainScreenVC())
        mainNav.isNavigationBarHidden = true

        viewControllers = [TikTokViewController(), mainNav]
        selectedIndex = 1
        tabBar.isHidden = true
        tabBarView.isUserInteractionEnabled = true
        view.addSubview(tabBarView)
        tabBarView.pin(.leading).to(tabBar, .leading).equal()
        tabBarView.pin(.trailing).to(tabBar, .trailing).equal()
        tabBarView.pin(.bottom).to(tabBar, .bottom).equal()
        tabBarView.pin(.height).const(tabBarHeight).equal()
        setupTabBarView(view: tabBarView)
    }

    func changeTab(tab: Int) {
        selectedIndex = tab
    }

    func setupTabBarView(view: UIView) {
        let home = UIImageView(image: .init(named: "Home"))
        let ex = UIImageView(image: .init(named: "Ex"))
        let dict = UIImageView(image: .init(named: "Dict"))

        view.addSubview(home)
        view.addSubview(ex)
        view.addSubview(dict)

        home.pin(.centerX).to(view).equal()
        home.pin(.centerY).to(view).equal()
        ex.pin(.centerY).to(view).equal()
        dict.pin(.centerY).to(view).equal()

        ex.pin(.trailing).to(home, .leading).const(-40).equal()
        dict.pin(.leading).to(home, .trailing).const(40).equal()

        ex.addTapHandler { [weak self] in
            self?.selectedIndex = 0
        }

        home.addTapHandler { [unowned self] in
            let currentIndex = self.selectedIndex
            if currentIndex == 1 {
                let codeVc = QRCodeScannerViewController()
                self.present(codeVc, animated: true)
                codeVc.onCode = { code in
                    let overlayVC = OverlayPanelViewController(wsID: code)
                    overlayVC.loadViewIfNeeded()
                    codeVc.dismiss(animated: true) {
                        viewControllers?[1].navigationController?.pushViewController(overlayVC, animated: true)
                    }
                }
            } else {
                self.selectedIndex = 1
            }
        }

        dict.addTapHandler { [weak self] in
            (self?.viewControllers?[2] as? DictionaryVC)?.words = DefinitionHandler.definitions
             self?.selectedIndex = 2
        }
    }
}
