//
//  DictionaryVC.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 24.08.2021.
//

import UIKit
import Networking
import Player_iOS
import SharedCode
import Combine

class DictionaryVC: UIViewController {
    let stack = UIStackView()
    let scrollView = UIScrollView()
    var words: [String: [String]] = [:] {
        didSet {
            addWords()
        }
    }
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
    }

    func addWords() {
        do {
            let label = UILabel(text: "Словарь", font: .systemFont(ofSize: 23, weight: .semibold), color: .white)
            stack.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
        }
        words.keys
            .forEach({ key in
                stack.addArrangedSubview(MovieCard.wordRowView(word: key) { word in
                    let vc = WordVC()
                    vc.word = (word, self.words[word]?.first ?? "")
                    self.present(vc, animated: true, completion: nil)
                })
            })
    }
}
