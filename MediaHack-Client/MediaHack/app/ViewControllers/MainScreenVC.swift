//
//  MainScreenVC.swift
//  MediaHack
//
//  Created by Vitalii Stikhurov on 21.08.2021.
//

import UIKit
import Combine
import Player

class MainScreenVC: UIViewController {

    let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        stack.axis = .vertical
        stack.spacing = 16

    }

    private func movieView(element: CinemaListElement) -> UIView {
        let wrapper = UIView()
        let imageView = UIImageView()
        let title = UILabel()
        let tags = UILabel()
    }

    private func loadMovies() -> AnyPublisher<[CinemaListElement], Error> {
        let session = URLSession.shared
        let url = URL(string: "http://178.154.197.24/cinemaList").unsafelyUnwrapped
        let decoder = JSONDecoder()

        return session
            .dataTaskPublisher(for: url)
            .tryMap { data, _ in
                try decoder.decode([CinemaListElement].self, from: data)
            }
            .eraseToAnyPublisher()
    }
}
