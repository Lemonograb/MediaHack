//
//  MovieCard.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 22.08.2021.
//

import UIKit
import Networking
import Player_iOS
import Nuke

class MovieCard: UIViewController {
    enum ViewState {
        case info
        case dict
    }
    let stack = UIStackView()
    let infoStackView = UIStackView()
    let dictStackView = UIStackView()
    let scrollView = UIScrollView()
    private var bag = Set<AnyCancellable>()

    var viewState: ViewState! {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                if viewState == .dict {
                    dictStackView.isHidden = false
                    infoStackView.isHidden = true
                } else {
                    dictStackView.isHidden = true
                    infoStackView.isHidden = false
                }
            }
        }
    }

    var movie: Movie!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "MainBackground")
        viewState = .info
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
        let backButton = UIImageView(image: .init(named: "ic_arrow"))
        view.addSubview(backButton)
        backButton.pinEdges(to: view.safeAreaLayoutGuide, top: 8, left: 8, bottom: .nan, right: .nan)
        backButton.addTapHandler { [unowned self] in
            navigationController?.popViewController(animated: true)
        }
        do {
            let iv = UIImageView()
            Nuke.loadImage(with: movie.photoURL, into: iv)
            let imageHeder = iv.fadeView()
            imageHeder.pin(.height).const(428).equal()
            stack.addArrangedSubview(imageHeder)

            let title = UILabel(text: movie.name, font: .systemFont(ofSize: 31), color: .white)
            imageHeder.addSubview(title)
            title.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 54, right: 16))

            let rating = UILabel(text: String(movie.rating), font: .systemFont(ofSize: 25), color: .white)
            imageHeder.addSubview(rating)
            rating.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 16, right: 16))

            let watch = UIImageView(image: .init(named: "watch"))
            imageHeder.addSubview(watch)
            watch.pin(.centerY).to(rating).equal()
            watch.pinToSuperView(.trailing).const(-16).equal()

            watch.addTapHandler { [unowned self] in
                play()
            }

            let tags = CaruselView(itemsView: movie.tags.map { tag in
                let tagView = UILabel(text: "\(tag)", font: .systemFont(ofSize: 13), color: .white)
                tagView.textAlignment = .center
                let wrapper = UIView()
                wrapper.backgroundColor = UIColor(red: 0.608, green: 0.318, blue: 0.878, alpha: 1)
                wrapper.layer.cornerRadius = 4
                wrapper.layer.masksToBounds = true
                wrapper.addSubview(tagView)
                tagView.pinEdgesToSuperView(edges: .init(top: 4, left: 8, bottom: 4, right: 8))
                return wrapper
            })
            imageHeder.addSubview(tags)
            tags.pinEdgesToSuperView(edges: .init(top: .nan, left: 0, bottom: 99, right: 0))
        }

        do {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fillProportionally
            let label1 = UILabel(text: "Сюжет", font: .systemFont(ofSize: 15), color: viewState == .info ? .white : UIColor(named: "secondaryText")!)
            label1.textAlignment = .center

            stackView.addArrangedSubview(label1)

            let separator = UIView()
            separator.pin(.height).const(16).equal()
            separator.pin(.width).const(1).equal()
            separator.backgroundColor = .white
            stackView.addArrangedSubview(separator)

            let label2 = UILabel(text: "Словарь", font: .systemFont(ofSize: 15), color: viewState == .dict ? .white : UIColor(named: "secondaryText")!)
            label2.textAlignment = .center
            label2.addTapHandler { [unowned self] in
                self.viewState = .dict
                label2.textColor = .white
                label1.textColor = UIColor(named: "secondaryText")!
            }
            label1.addTapHandler { [unowned self] in
                self.viewState = .info
                label1.textColor = .white
                label2.textColor = UIColor(named: "secondaryText")!
            }
            stackView.addArrangedSubview(label2)
            stack.addArrangedSubview(stackView)
        }

        do {
            stack.addArrangedSubview(dictStackView)
            dictStackView.axis = .vertical
            stack.alignment = .fill
            dictStackView.spacing = 16
            movie.dictionary.forEach {
                dictStackView.addArrangedSubview(Self.wordRowView(word: $0) { word in
                    API.define(word: word)
                        .sink(receiveCompletion: {_ in }, receiveValue: ({ def in
                            DefinitionHandler.add(word: word, def: def)
                            DispatchQueue.main.async {
                                let vc = WordVC()
                                vc.word = (word, def.first ?? "")
                                self.present(vc, animated: true, completion: nil)
                            }
                        }))
                        .store(in: &self.bag)

                })
            }

            let buttonText = UILabel(text: "Добавить в словарь", font: .systemFont(ofSize: 20), color: .black)
            buttonText.textAlignment = .center
            let wrapper = UIView()
            wrapper.backgroundColor = UIColor(red: 1, green: 0.686, blue: 0.004, alpha: 1)
            wrapper.layer.cornerRadius = 8
            wrapper.layer.masksToBounds = true
            wrapper.addSubview(buttonText)
            buttonText.pinToSuperView(.centerY).equal()
            buttonText.pinToSuperView(.centerX).equal()
            wrapper.pin(.height).const(56).equal()
            let wrapperwrapper = UIView()
            wrapperwrapper.addSubview(wrapper)
            wrapper.pinEdgesToSuperView(edges: .init(top: 0, left: 16, bottom: 0, right: 16))
            wrapperwrapper.addTapHandler {
                self.movie.dictionary.forEach({ word in
                    API.define(word: word)
                        .sink(receiveCompletion: {_ in }, receiveValue: ({ def in
                            DefinitionHandler.add(word: word, def: def)
                        }))
                        .store(in: &self.bag)
                })
            }
            dictStackView.addArrangedSubview(wrapperwrapper)
        }

        do {
            stack.addArrangedSubview(infoStackView)
            infoStackView.axis = .vertical
            infoStackView.spacing = 16
            let movieListDescription = UILabel(text: movie.movieListDescription, font: .systemFont(ofSize: 15), color: .white, numberOfLines: 5).padding(.init(top: 0, left: 16, bottom: 0, right: 16))
            infoStackView.addArrangedSubview(movieListDescription)

            do {
                let label = UILabel(text: "Рецензии", font: .systemFont(ofSize: 23, weight: .semibold), color: .white)
                infoStackView.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
                infoStackView.setCustomSpacing(0, after: infoStackView.arrangedSubviews.last!)
            }
            do {
                infoStackView.addArrangedSubview(CaruselView(itemsView: movie.reviews.map {
                    reviewView(review: $0)
                }))
            }

            do {
                let label = UILabel(text: "Рекомендации", font: .systemFont(ofSize: 23, weight: .semibold), color: .white)
                infoStackView.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
                infoStackView.setCustomSpacing(0, after: infoStackView.arrangedSubviews.last!)
            }
            do {
                infoStackView.addArrangedSubview(CaruselView(itemsView: allMovies.filter({ movie.relevantCinemaIDS.contains($0.id) }).map { movie in
                    let view = UIImageView()
                    Nuke.loadImage(with: movie.photoURL, into: view)
                    view.layer.cornerRadius = 8
                    view.layer.masksToBounds = true
                    view.pin(.height).const(239).equal()
                    view.pin(.width).const(150).equal()
                    view.addTapHandler { [unowned self] in
                        let vc = MovieCard()
                        vc.movie = movie
                        navigationController?.pushViewController(vc, animated: true)
                    }
                    return view
                }))
            }
        }
    }

    func reviewView(review: Networking.Review) -> UIView {
        let wrapper = UIView()
        let icon = UIImageView(image: UIImage(named: "User - Scan"))
        let name = UILabel(text: review.name, font: .systemFont(ofSize: 13), color: .white)
        let date = UILabel(text: review.dateStr, font: .systemFont(ofSize: 11), color: UIColor(named: "secondaryText")!)
        let text = UILabel(text: review.text, font: .systemFont(ofSize: 13), color: UIColor(named: "secondaryText")!)

        wrapper.addSubview(icon)
        wrapper.addSubview(name)
        wrapper.addSubview(date)
        wrapper.addSubview(text)

        icon.pinEdgesToSuperView(edges: .init(top: 16, left: 16, bottom: .nan, right: .nan))
        name.pinEdgesToSuperView(edges: .init(top: 16, left: .nan, bottom: .nan, right: .nan))
        name.pin(.left).to(icon, .right).const(12).equal()

        date.pin(.left).to(icon, .right).const(12).equal()
        date.pin(.top).to(name, .bottom).equal()

        text.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 25, right: 16))
        text.pin(.top).to(date, .bottom).const(8).equal()

        wrapper.backgroundColor = UIColor(red: 0.243, green: 0.251, blue: 0.302, alpha: 1)
        wrapper.layer.cornerRadius = 8
        wrapper.layer.masksToBounds = true
        wrapper.pin(.width).const(256).equal()
        return wrapper
    }

    static func wordRowView(word: String, onTap: @escaping (String) -> Void) -> UIView {
        let row = UIView()
        let wordView = UILabel(text: word, font: .systemFont(ofSize: 15), color: .white)
        let separator = UIView()
        let icon = UIImageView(image: .init(named: "Right_Light_pink"))
        separator.pin(.height).const(1).equal()
        separator.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.06)
        row.addSubview(wordView)
        row.addSubview(separator)
        row.addSubview(icon)
        wordView.pinEdgesToSuperView(edges: .init(top: 0, left: 16, bottom: .nan, right: .nan))
        icon.pin(.centerY).to(wordView, .centerY).equal()
        icon.pinToSuperView(.right).const(-16).equal()
        icon.pin(.left).to(wordView, .right).const(8).equal()
        separator.pinEdgesToSuperView(edges: .init(top: .nan, left: 16, bottom: 0, right: 16))
        separator.pin(.top).to(wordView, .bottom).const(12).equal()
        row.addTapHandler {
            onTap(word)
        }
        return row
    }

    func play() {
        let vc = PlayerViewController()
        present(vc, animated: true, completion: nil)
    }
}

extension UIView {
    class UIViewFadeWrapper<ViewType: UIView>: UIView {
        var wrappedView: ViewType! {
            didSet {
                self.addSubview(wrappedView)
                wrappedView.pinEdgesToSuperView()
            }
        }
        var gradientLayer: CAGradientLayer = {
            let gradient = CAGradientLayer()
            gradient.type = .axial
            gradient.colors = [UIColor.clear.cgColor, UIColor(named: "MainBackground")!.cgColor]

            gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            return gradient
        }()

        override func layoutSubviews() {
            super.layoutSubviews()
            wrappedView.layer.masksToBounds = true
            if self.gradientLayer.superlayer == nil {
                self.wrappedView.layer.insertSublayer(self.gradientLayer, at: 0)
            }
            wrappedView.layer.masksToBounds = true
            self.gradientLayer.frame = wrappedView.bounds
        }
    }

    func fadeView() -> UIView {
        let view = UIViewFadeWrapper()
        view.wrappedView = self
        return view
    }
}
