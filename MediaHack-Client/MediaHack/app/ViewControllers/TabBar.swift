//
//  TabBar.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 22.08.2021.
//

import UIKit
import SubtitlesOverlay

class NavigationMenuBaseController: UITabBarController {
    var tabBarHeight: CGFloat = 96.0
    let tabBarView = UIImageView(image: .init(named: "tabBarFrame"))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadTabBar()
    }

    func loadTabBar() {
        self.viewControllers = [MainViewController(), MainScreenVC(), SubtitlesOverlayViewController()]
        self.selectedIndex = 1
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
        self.selectedIndex = tab
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

        home.addTapHandler { [weak self] in
            self?.selectedIndex = 1
        }

        ex.addTapHandler { [weak self] in
            self?.selectedIndex = 0
        }

        dict.addTapHandler { [weak self] in
            self?.selectedIndex = 2
        }
    }
}
