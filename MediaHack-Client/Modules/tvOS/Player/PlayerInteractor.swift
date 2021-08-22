import AVKit
import Combine
import Foundation
import Networking
import SharedCode

final class PlayerInteractor {
    private typealias TimeToSubtitle = (key: Double, value: Networking.Subtitle)

    struct Model {
        struct Content {
            let playerURL: URL
            let movie: Networking.Movie
            let subtitles: Networking.MovieSubtitles
        }

        var error: Error?
        var content: Content?
    }

    struct PlayerModel {
        let enSubtitle: NSAttributedString
    }

    private struct SubtitlesHolder {
        let eng: [TimeToSubtitle]
        let ru: [TimeToSubtitle]
    }

    var modelPublisher: AnyPublisher<Model, Never> {
        return modelSubject.eraseToAnyPublisher()
    }

    var playerModelPublisher: AnyPublisher<PlayerModel, Never> {
        return playerModelSubject.eraseToAnyPublisher()
    }

    private let modelSubject = CurrentValueSubject<Model, Never>(.init())
    private let playerModelSubject = PassthroughSubject<PlayerModel, Never>()

    private let timeToSubtitleSubject = PassthroughSubject<SubtitlesHolder, Never>()
    private let playerTimeSubject = PassthroughSubject<CMTime, Never>()
    private var bag = Set<AnyCancellable>()

    init() {
        WSManager.shared.connectToWebSocket(type: .tv, id: nil)
//        playingStatusSubject.sink { isPlaying in
//            WSManager.shared.sendStatus(isPlaying ? .start : .stop)
//        }.store(in: &bag)

        playerTimeSubject.sink { time in
            WSManager.shared.sendStatus(.play(sec: time.seconds))
        }.store(in: &bag)

        modelSubject.compactMap { m in
            m.content?.subtitles
        }.map { subtitles -> SubtitlesHolder in
            func iterate(over model: [Networking.Subtitle]) -> [TimeToSubtitle] {
                let model = model.sorted { s1, s2 in
                    s1.start.timeInSeconds < s2.start.timeInSeconds
                }
                var lowerboundToSubtitle: [TimeToSubtitle] = []
                lowerboundToSubtitle.reserveCapacity(model.count)
                for subtitle in model {
                    let adjustedKey = subtitle.start.timeInSeconds - 2586.5
                    lowerboundToSubtitle.append((key: adjustedKey, value: subtitle))
                }
                return lowerboundToSubtitle
            }
            return SubtitlesHolder(eng: iterate(over: subtitles.en), ru: iterate(over: subtitles.ru))
        }.subscribe(timeToSubtitleSubject).store(in: &bag)

        playerTimeSubject.withLatestFrom(timeToSubtitleSubject) { time, subtitles -> PlayerModel? in
            let sec = time.seconds
            guard
                let enSubtitle = subtitles.eng.first(where: { k, v in
                    k >= sec && sec <= v.end.timeInSeconds
                })?.value
            else {
                return nil
            }
            return PlayerModel(enSubtitle: WordsTokenizer.process(text: enSubtitle.text))
        }.compactMap { $0 }.subscribe(playerModelSubject).store(in: &bag)
    }

    func loadData() -> AnyCancellable {
        return API.getMovies().map { list in
            list[0]
        }
        .flatMap { movie in
            API.getSubtitle(movie: movie).map { subtitles in
                (movie, subtitles)
            }
        }
        .map { movie, subtitles -> Model in
            Model(error: nil, content: Model.Content(playerURL: trailerURL, movie: movie, subtitles: subtitles))
        }
        .catch { (e: Error) -> Just<Model> in
            let model = Model(error: e, content: nil)
            return Just(model)
        }.subscribe(modelSubject)
    }

    func set(time: CMTime) {
        playerTimeSubject.send(time)
    }
}

private let trailerURL = URL(string: "https://strm.yandex.ru/vh-ott-converted/ott-content/530389814-4a54e1d887da77c3ab345f7635ca9b59/master.m3u8?from=ott-kp&hash=b60bc9cbe1e6783ff44e51c6568b8386&vsid=b9690d561690dbd1eff4bfe5c79a1b9304a4d904a019xWEBx6710x1629612671&video_content_id=4a54e1d887da77c3ab345f7635ca9b59&session_data=1&preview=1&t=1629612671617").unsafelyUnwrapped
