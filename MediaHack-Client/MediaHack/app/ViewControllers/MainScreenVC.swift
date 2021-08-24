//
//  MainScreenVC.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import Combine
import Networking
import Player_iOS
import UIKit
import Nuke

var allMovies: [Movie] = []
class MainScreenVC: UIViewController {
    private var bag = Set<AnyCancellable>()
    let stack = UIStackView()
    let scrollView = UIScrollView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "MainBackground")

        API.getMovies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { c in
                if case let .failure(err) = c {
                    assertionFailure(err.localizedDescription)
                }
            }, receiveValue: { [weak self] movies in
                allMovies = movies
                self?.setupViews(movies: movies)
            })
            .store(in: &bag)
    }

    private func setupViews(movies: [Movie]) {
        view.addSubview(scrollView)
        scrollView.pinEdgesToSuperView()
        scrollView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 16
        stack.pin(.width).const(UIScreen.main.bounds.width).equal()
        stack.pinEdgesToSuperView(edges: .init(top: 0, left: 0, bottom: 48, right: 0))
        do {
            let label = UILabel()
            label.text = "Подобрали фильмы под ваш уровень языка"
            label.font = .systemFont(ofSize: 27, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 0
            stack.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
        }
        do {
            let views = movies.map { element -> UIView in
                let view = movieView(element: element)
                view.addTapHandler { [weak self] in
                    self?.openFilm(movie: element, relevant: movies)
                }
                return view
            }
            let carusel = CaruselView(itemsView: views)
            stack.addArrangedSubview(carusel)
        }
        do {
            let carusel = CaruselView(itemsView: ["космос", "любовь", "карьера", "традиции", "животные", "криминал"].map { tag(tag: $0) })
            stack.addArrangedSubview(carusel)
        }
        do {
            let label = UILabel()
            label.text = "По темам"
            label.font = .systemFont(ofSize: 27, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 0
            stack.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
            stack.setCustomSpacing(0, after: stack.arrangedSubviews.last!)
        }
        do {
            let carusel = CaruselView(itemsView: ["1", "2", "3", "4", "5"].map { themeCard(id: $0) })
            stack.addArrangedSubview(carusel)
        }
        do {
            let label = UILabel()
            label.text = "Топ"
            label.font = .systemFont(ofSize: 27, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 0
            stack.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
            stack.setCustomSpacing(0, after: stack.arrangedSubviews.last!)
        }
        do {
            let views = movies.map { element -> UIView in
                let view = movieView(element: element)
                view.addTapHandler { [weak self] in
                    self?.openFilm(movie: element, relevant: movies)
                }
                return view
            }
            let carusel = CaruselView(itemsView: views)
            stack.addArrangedSubview(carusel)
        }
        do {
            let label = UILabel()
            label.text = "Уровнем выше"
            label.font = .systemFont(ofSize: 27, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 0
            stack.addArrangedSubview(label.padding(.init(top: 0, left: 16, bottom: 0, right: 16)))
            stack.setCustomSpacing(0, after: stack.arrangedSubviews.last!)
        }
        do {
            let views = movies.map { element -> UIView in
                let view = movieView(element: element)
                view.addTapHandler { [weak self] in
                    self?.openFilm(movie: element, relevant: movies)
                }
                return view
            }
            let carusel = CaruselView(itemsView: views)
            stack.addArrangedSubview(carusel)
        }
    }

    private func themeCard(id: String) -> UIView {
        let imageView = UIImageView(image: UIImage(named: id))

        imageView.addTapHandler { [weak self] in
            self?.openTheme(themeID: id)
        }

        return imageView
    }

    private func tag(tag: String) -> UIView {
        let label = UILabel()
        label.text = tag
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor(named: "MainBackground")
        label.backgroundColor = .white
        label.numberOfLines = 1
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 16
        label.pin(.height).const(32).equal()
        label.pin(.width).const(77).equal()
        label.addTapHandler { [weak self] in
            self?.openTag(tag: tag)
        }
        return label
    }

    private func movieView(element: Movie) -> UIView {
        let wrapper = UIView()
        let imageView = UIImageView()
        Nuke.loadImage(with: element.photoURL, into: imageView)
        let title = UILabel()
        let tags = UILabel()
        let rating = UILabel()

        wrapper.addSubview(imageView)
        imageView.pinEdgesToSuperView(edges: .init(top: 0, left: 0, bottom: .nan, right: 0))
        imageView.pin(.height).const(188).equal()
        imageView.pin(.width).const(164).equal()
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 8

        imageView.addSubview(rating)
        rating.text = "\(element.rating)"
        rating.font = .systemFont(ofSize: 11)
        rating.textAlignment = .center
        rating.backgroundColor = UIColor(red: 0.231, green: 0.702, blue: 0.227, alpha: 1)
        rating.layer.masksToBounds = true
        rating.layer.cornerRadius = 4
        rating.textColor = .white
        rating.pin(.height).const(15).equal()
        rating.pin(.width).const(23).equal()
        rating.pinEdgesToSuperView(edges: .init(top: .nan, left: 8, bottom: 8, right: .nan))

        wrapper.addSubview(title)
        title.text = element.name
        title.font = .systemFont(ofSize: 15)
        title.textColor = .white
        title.pinToSuperView(.leading).equal()
        title.pin(.top).to(imageView, .bottom).const(4).equal()

        wrapper.addSubview(tags)
        tags.text = element.tags.joined(separator: ", ")
        tags.font = .systemFont(ofSize: 11)
        tags.textColor = UIColor(named: "secondaryText")
        tags.pinToSuperView(.leading).equal()
        tags.pin(.top).to(title, .bottom).equal()
        tags.pinToSuperView(.bottom).equal()

        return wrapper
    }

    private func openFilm(movie: Movie, relevant: [Movie]) {
        let vc = MovieCard()
        vc.movie = movie
        navigationController?.pushViewController(vc, animated: true)
    }

    private func openTag(tag: String) {}

    private func openTheme(themeID: String) {}
}

extension UIImageView {
    static var imageCach: [String: UIImage] = [:]
    convenience init(urlString: String) {
        self.init()
        if let image = Self.imageCach[urlString] {
            DispatchQueue.main.async { [weak self] in
                self?.image = image
            }
        } else {
            guard let url = URL(string: urlString) else { return }
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
            request.httpMethod = "GET"

            let session = URLSession.shared
            let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] data, _, error -> Void in
                if let error = error {
                    print(error)
                } else {
                    guard let data = data else { return }
                    let image = UIImage(data: data)
                    Self.imageCach[urlString] = image
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            })
            dataTask.resume()
        }
    }
}

extension UIView {
    func padding(_ inset: UIEdgeInsets) -> UIView {
        let view = UIView()
        view.addSubview(self)
        pinEdgesToSuperView(edges: inset)
        return view
    }
}

extension UILabel {
    convenience init(text: String, font: UIFont, color: UIColor, numberOfLines: Int = 0) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = color
        self.numberOfLines = numberOfLines
    }
}
