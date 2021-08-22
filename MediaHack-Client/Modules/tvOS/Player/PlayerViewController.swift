import AVKit
import Combine
import SharedCode
import UIKit

let videoURL = URL(string: "https://strm.yandex.ru/vh-kp-converted/ott-content/391640856-4ddd12172749641eb39e86ad8e58cd6e/ysign1=b7cb997038730a9cdb9bff7e59a224a206d9ff3cb6bd4ae71c91a6ff4b87755a,abcID=1358,from=ott-kp,pfx,sfx,ts=612d93bb/master.m3u8?partner-id=139995&video-category-id=1014&imp-id=undefined&gzip=1&from=discovery&vsid=a17e1d424f6a900381ac160e60128ff616186dfed6bdxWEBx6101x1629528005&adsid=2b2fedbacadc771c664cf6e501d6143b62aaacf841c5xWEBx6101x1629528005&session_data=1&preview=1&t=1629528006045").unsafelyUnwrapped

struct Movie {
    let lowerboundToSubtitle: [(key: Double, value: Subtitle)]
}

public final class PlayerViewController: BaseViewController {
    private let interactor = PlayerInteractor()
    private var playerView: PlayerView!
    private var bag = Set<AnyCancellable>()
    private var playerObserverToken: Any?

    override public func setup() {
        interactor.modelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] model in
                self.update(with: model)
            }.store(in: &bag)

        interactor.playerModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] model in
                self.updatePlayer(with: model)
            }.store(in: &bag)

        interactor.loadData().store(in: &bag)
    }

    private func update(with model: PlayerInteractor.Model) {
        if let error = model.error {
            print(error.localizedDescription)
        } else if let content = model.content {
            update(with: content)
        }
    }

    private func update(with content: PlayerInteractor.Model.Content) {
        playerView?.removeFromSuperview()
        playerObserverToken.flatMap { token in
            playerView?.player.removeTimeObserver(token)
        }

        playerView = PlayerView(
            model: PlayerView.Model(
                url: content.playerURL,
                subtitlesViewModel: SubtitlesView.Model(
                    onWordSelected: { [unowned self] w in
                        self.playerView.isPlaying = false
                        self.translateWord(w)
                    }
                )
            )
        )
        view.addSubview(playerView)
        playerView.pinEdgesToSuperView()

        playerObserverToken = playerView.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .global(qos: .userInteractive)
        ) { [unowned self] offset in
            self.interactor.set(time: offset)
        }
        playerView.player.play()
    }

    private func updatePlayer(with model: PlayerInteractor.PlayerModel) {
        playerView?.subtitlesView.text = model.enSubtitle
    }

    private func setupPlayer(url: URL) {}

    @inline(__always)
    private func findSubtitle(for time: Double, in movie: Movie) -> Subtitle? {
        return movie.lowerboundToSubtitle.first { (key: Double, value: Subtitle) in
            key >= time && value.end.timeInSeconds >= time
        }?.value
    }

    private func setupPlayer(with movie: Movie) {
        if let first = findSubtitle(for: 0, in: movie) {
            playerView.subtitlesView.text = WordsTokenizer.process(text: first.text)
        }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        playerView.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [unowned self] offset in
            let time = offset.seconds
            guard let entry = findSubtitle(for: time, in: movie) else {
                print("skipped", time)
                return
            }

            let text = WordsTokenizer.process(text: entry.text)
            self.playerView.subtitlesView.text = text
        }
        playerView.subtitlesView.isHidden = false
        DispatchQueue.main.async { [self] in
            playerView.player.seek(to: CMTime(value: CMTimeValue(0), timescale: CMTimeScale(NSEC_PER_SEC)))
            // playerView.player.playImmediately(atRate: 0.25)
            playerView.player.play()
        }
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

    private func translateWord(_ word: String) {}
}

// MARK: - CinemaListElement

public struct CinemaListElement: Codable {
    public let ruSubtitles: [Subtitle]
    public let reviews: [Review]
    public let engSubtitles: [Subtitle]
    public let name: String
    public let relevantCinemaIDS: [String]
    public let cinemaListDescription: String
    public let photoURL: String
    public let tags: [String]
    public let rating: Double
    public let id: String
    public let dictionary: [String]
    public let url: String

    public enum CodingKeys: String, CodingKey {
        case ruSubtitles, reviews, engSubtitles, name
        case relevantCinemaIDS = "relevantCinemaIds"
        case cinemaListDescription = "description"
        case photoURL = "photoUrl"
        case tags, rating, id, dictionary, url
    }
}

// MARK: - Subtitle

public struct Subtitle: Codable {
    public let start, end: SubtitleTiming
    public let text: [String]
}

// MARK: - End

public struct SubtitleTiming: Codable {
    let timeInSeconds: Double
}

// MARK: - Review

public struct Review: Codable {
    let name, text, dateStr: String
}
