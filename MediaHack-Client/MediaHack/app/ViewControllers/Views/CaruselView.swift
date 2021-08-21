//
//  CaruselView.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import UIKit

class CaruselView: UIView {
    let scrollView = UIScrollView()
    let contentView = UIView()
    let itemsView: [UIView]

    init(itemsView: [UIView]) {
        self.itemsView = itemsView
        super.init(frame: .zero)

        addSubview(scrollView)
        scrollView.pinEdgesToSuperView()
        scrollView.addSubview(contentView)
        contentView.pinEdgesToSuperView()
        contentView.pinToSuperView(.height).equal()
        scrollView.isScrollEnabled = true
        scrollView.showsHorizontalScrollIndicator = false

        for (index, itemView) in itemsView.enumerated() {
            contentView.addSubview(itemView)
            if index == 0 {
                itemView.pinEdgesToSuperView(edges: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: .nan))
            } else if index == itemsView.count - 1 {
                itemView.pinEdgesToSuperView(edges: UIEdgeInsets(top: 8, left: .nan, bottom: 8, right: 8))
                itemView.pin(.left).to(itemsView[index - 1], .right).const(8).equal()
            } else {
                itemView.pinEdgesToSuperView(edges: UIEdgeInsets(top: 8, left: .nan, bottom: 8, right: .nan))
                itemView.pin(.left).to(itemsView[index - 1], .right).const(8).equal()
            }
        }

    }

    convenience init() {
        let arr: [UIView] = [
            {
                let view = UIView()
                view.pin(.width).const(169).equal()
                view.pin(.height).const(178).equal()
                view.backgroundColor = .red
                return view
            }(),
            {
                let view = UIView()
                view.pin(.width).const(169).equal()
                view.pin(.height).const(178).equal()
                view.backgroundColor = .red
                return view
            }(),
            {
                let view = UIView()
                view.pin(.width).const(169).equal()
                view.pin(.height).const(178).equal()
                view.backgroundColor = .red
                return view
            }(),
            {
                let view = UIView()
                view.pin(.width).const(169).equal()
                view.pin(.height).const(178).equal()
                view.backgroundColor = .red
                return view
            }()
        ]
        self.init(itemsView: arr)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
