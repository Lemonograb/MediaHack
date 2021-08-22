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

    override public init() {
        super.init()
        self.playerView = PlayerView(
            model: PlayerView.Model(
                subtitlesViewModel: SubtitlesView.Model(
                    onWordSelected: { [unowned self] w in
                        self.playerView.isPlaying = false
                        self.translateWord(w)
                    }
                )
            )
        )
        interactor.loadData().sink(
            receiveCompletion: { _ in },
            receiveValue: { model in
                print(model)
            }
        ).store(in: &bag)
    }

    private let blurLabel = UILabel()

    override public func setup() {
        view.addSubview(playerView)
        playerView.pinEdgesToSuperView()
        playerView.subtitlesView.isHidden = true

        blurLabel.backgroundColor = .clear
        blurLabel.numberOfLines = 0
        blurLabel.attributedText =
            "Uncomfortable silences. Why do we feel it's necessary\nto yak about bullshit in order to be comfortable?"
                .builder
                .font(UIFont.systemFont(ofSize: 18, weight: .medium))
                .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1)).result

        view.addSubview(blurLabel)
        blurLabel.pinCenter(to: view)

        blurLabel.layoutIfNeeded()
        blurLabel.blur(radius: 2)
//        let visualEffectView = VisualEffectView(frame: blurLabel.bounds)
//        visualEffectView.colorTint = #colorLiteral(red: 0.1960784314, green: 0.2, blue: 0.2392156863, alpha: 1)
//        visualEffectView.colorTintAlpha = 0.2
//        visualEffectView.blurRadius = 1
//        visualEffectView.scale = 1
//        blurLabel.addSubview(visualEffectView)

        loadMovies()
            .map { cinemaList in
                let firstMovie = cinemaList[0]
                let engSubtitles = firstMovie.engSubtitles.sorted { s1, s2 in
                    s1.start.timeInSeconds < s2.start.timeInSeconds
                }
                var lowerboundToSubtitle: [(key: Double, value: Subtitle)] = []
                lowerboundToSubtitle.reserveCapacity(engSubtitles.count)
                for subtitle in engSubtitles {
                    let adjustedKey = subtitle.start.timeInSeconds - 28.153
                    lowerboundToSubtitle.append((key: adjustedKey, value: subtitle))
                }
                return Movie(lowerboundToSubtitle: lowerboundToSubtitle)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { c in
                    if case let .failure(err) = c {
                        assertionFailure(err.localizedDescription)
                    }
                },
                receiveValue: { [unowned self] movie in
                    self.setupPlayer(with: movie)
                }
            ).store(in: &bag)
    }

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

struct CinemaListElement: Codable {
    let ruSubtitles: [Subtitle]
    let reviews: [Review]
    let engSubtitles: [Subtitle]
    let name: String
    let relevantCinemaIDS: [String]
    let cinemaListDescription: String
    let photoURL: String
    let tags: [String]
    let rating: Double
    let id: String
    let dictionary: [String]
    let url: String

    enum CodingKeys: String, CodingKey {
        case ruSubtitles, reviews, engSubtitles, name
        case relevantCinemaIDS = "relevantCinemaIds"
        case cinemaListDescription = "description"
        case photoURL = "photoUrl"
        case tags, rating, id, dictionary, url
    }
}

// MARK: - Subtitle

struct Subtitle: Codable {
    let start, end: SubtitleTiming
    let text: [String]
}

// MARK: - End

struct SubtitleTiming: Codable {
    let timeInSeconds: Double
}

// MARK: - Review

struct Review: Codable {
    let name, text, dateStr: String
}
