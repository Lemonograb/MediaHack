//
//  WordVC.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 24.08.2021.
//

import UIKit
import Networking
import Player_iOS
import SharedCode
import Combine

class WordVC: UIViewController {
    let stack = UIStackView()
    let scrollView = UIScrollView()
    var word: (String, String)!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "MainBackground")
        setupViews()
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.pinEdgesToSuperView()
        scrollView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 16
        stack.pin(.width).const(UIScreen.main.bounds.width).equal()
        stack.pinEdgesToSuperView(edges: .init(top: 0, left: 0, bottom: 48, right: 0))
        stack.addArrangedSubview(wordView())

            do {
                let wrapper = UIView()
                let icon = UIImageView(image: .init(named: "att"))
                let title = UILabel(text: "Распространенное слово", font: .systemFont(ofSize: 23, weight: .semibold), color: .white)
                let subtitle = UILabel(text: "Часто используется в речи неформальной беседы и может пригодиться в общении ", font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
                wrapper.addSubview(icon)
                wrapper.addSubview(title)
                wrapper.addSubview(subtitle)
                icon.pinEdgesToSuperView(edges: .init(top: 0, left: 16, bottom: .nan, right: .nan))
                title.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: .nan, right: 16))
                title.pin(.top).to(icon, .bottom).const(4).equal()
                subtitle.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 0, right: 16))
                subtitle.pin(.top).to(title, .bottom).const(4).equal()
                stack.addArrangedSubview(wrapper)
            }

        do {
            let wrapper = UIView()
            let sep = UIView()
            sep.pin(.height).const(1).equal()
            sep.backgroundColor = UIColor(red: 0.31, green: 0.31, blue: 0.31, alpha: 1)
            wrapper.addSubview(sep)
            sep.pinEdgesToSuperView(edges: .init(top: 0, left: 16, bottom: 0, right: 16))
            stack.addArrangedSubview(wrapper)
        }
        do {
            let buttonView1 = buttonView(text: "Уже знаю это слово", icon: "ok")
            let buttonView2 = buttonView(text: "Не хочу учить это слово", icon: "close")
            let buttonView3 = buttonView(text: "Пожаловаться на контент", icon: "report")
            
            buttonView1.addTapHandler {
                self.dismiss(animated: true, completion: nil)
            }
            buttonView2.addTapHandler {
                self.dismiss(animated: true, completion: nil)
            }
            buttonView3.addTapHandler {
                self.dismiss(animated: true, completion: nil)
            }
            stack.addArrangedSubview(buttonView1)
            stack.addArrangedSubview(buttonView2)
            stack.addArrangedSubview(buttonView3)
        }
    }

    func buttonView(text: String, icon: String) -> UIView {
        let layout = UIView()
        let icon = UIImageView(image: .init(named: icon))
        let text = UILabel(text: text, font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
        layout.addSubview(icon)
        layout.addSubview(text)
        icon.pinEdgesToSuperView(edges: .init(top: 16, left: 16, bottom: 16, right: .nan))
        text.pin(.centerY).to(icon).equal()
        text.pin(.left).to(icon, .right).const(16).equal()
        text.pin(.right).to(layout, .right).const(-16).equal()
        layout.backgroundColor = UIColor(red: 0.243, green: 0.251, blue: 0.302, alpha: 1)
        layout.layer.masksToBounds = true
        layout.layer.cornerRadius = 8
//        layout.pin(.height).const(66).equal()
        let wrapper = UIView()
        wrapper.addSubview(layout)
        layout.pinEdgesToSuperView(edges: .init(top: 0, left: 16, bottom: 0, right: 16))
        return wrapper
    }

    func wordView() -> UIView {
        let layout = UIView()
        let wordLabel = UILabel(text: word.0, font: .systemFont(ofSize: 23, weight: .semibold), color: .white)
        let defLabel = UILabel(text: word.1, font: .systemFont(ofSize: 15, weight: .semibold), color: .white)
        let playButton = UIImageView(image: .init(named: "Play"))
        playButton.addTapHandler {
            print("todo")
        }
        layout.addSubview(wordLabel)
        layout.addSubview(defLabel)
        layout.addSubview(playButton)

        wordLabel.pinEdgesToSuperView(edges: .init(top: 12, left: 16, bottom: .nan, right: .nan))
        defLabel.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 12, right: 16))
        defLabel.pin(.top).to(wordLabel, .bottom).const(4).equal()

        playButton.pin(.centerY).to(wordLabel).equal()
        playButton.pinEdgesToSuperView(edges: .init(top: .nan, left: .nan, bottom: .nan, right: 16))
        playButton.pin(.left).to(wordLabel, .right).const(16).equal()

        layout.backgroundColor = UIColor(red: 0.243, green: 0.251, blue: 0.302, alpha: 1)
        layout.layer.masksToBounds = true
        layout.layer.cornerRadius = 8
        let wrapper = UIView()
        wrapper.addSubview(layout)
        layout.pinEdgesToSuperView(edges: .init(top: 16, left: 16, bottom: 16, right: 16))
        return wrapper
    }
}
