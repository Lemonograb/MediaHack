import AVKit
import Combine
import Foundation
import Networking
import OverplayPanel_tvOS
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

    var model: Model {
        return modelSubject.value
    }

    var modelPublisher: AnyPublisher<Model, Never> {
        return modelSubject.eraseToAnyPublisher()
    }

    var playerModelPublisher: AnyPublisher<PlayerModel, Never> {
        return playerModelSubject.eraseToAnyPublisher()
    }

    var playingStatusPublisher: AnyPublisher<Bool, Never> {
        return playingStatusSubject.eraseToAnyPublisher()
    }

    var adjustPlayerTimePublisher: AnyPublisher<CMTime, Never> {
        return adjustedPlayerTimeSubject.eraseToAnyPublisher()
    }

    var qrCodePublisher: AnyPublisher<UIImage, Never> {
        return qrCodeSubject.eraseToAnyPublisher()
    }

    private static let adjustment: Double = 2589.5

    private let modelSubject = CurrentValueSubject<Model, Never>(.init())
    private let playerModelSubject = PassthroughSubject<PlayerModel, Never>()

    private let playingStatusSubject = PassthroughSubject<Bool, Never>()
    private let qrCodeSubject = PassthroughSubject<UIImage, Never>()
    private let timeToSubtitleSubject = CurrentValueSubject<SubtitlesHolder, Never>(.init(eng: [], ru: []))
    private let playerTimeSubject = PassthroughSubject<CMTime, Never>()
    private let adjustedPlayerTimeSubject = PassthroughSubject<CMTime, Never>()
    private var bag = Set<AnyCancellable>()

    init() {
        let decoder = JSONDecoder()
        WSManager.shared.connectToWebSocket(type: .tv, id: nil)
        WSManager.shared.receiveData(completion: { [weak self] text in
            if
                let data = text.data(using: .utf8),
                let status = try? decoder.decode(WSStatus.self, from: data)
            {
                switch status {
                case .start:
                    self?.playingStatusSubject.send(true)
                case .stop:
                    self?.playingStatusSubject.send(false)
                case .play, .cancel:
                    break
                case let .playAt(sec):
                    self?.adjustedPlayerTimeSubject.send(CMTime(seconds: sec, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                }
            }
        })

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
                    let adjustedKey = subtitle.start.timeInSeconds - PlayerInteractor.adjustment
                    lowerboundToSubtitle.append((key: adjustedKey, value: subtitle))
                }
                return lowerboundToSubtitle
            }
            return SubtitlesHolder(eng: iterate(over: subtitles.en), ru: iterate(over: subtitles.ru))
        }.subscribe(timeToSubtitleSubject).store(in: &bag)

        playerTimeSubject.withLatestFrom(timeToSubtitleSubject) { time, subtitles -> PlayerModel? in
            let sec = time.seconds
            let adjustedTime = sec + PlayerInteractor.adjustment
            guard
                let enSubtitle = subtitles.eng.first(where: { _, v in
                    if v.end.timeInSeconds < adjustedTime {
                        return false
                    } else {
                        return v.start.timeInSeconds <= adjustedTime && adjustedTime <= v.end.timeInSeconds
                    }
                })?.value
            else {
                return nil
            }
            return PlayerModel(enSubtitle: WordsTokenizer.process(text: enSubtitle.text))
        }.compactMap { $0 }.subscribe(playerModelSubject).store(in: &bag)
    }

    func requestQRCode() {
        if let id = WSManager.shared.deviceId, let image = generateQRCode(from: id) {
            qrCodeSubject.send(image)
        }
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

    func set(playing isPlaying: Bool) {
        WSManager.shared.sendStatus(isPlaying ? .start : .stop)
    }

    func overlayModel(for time: CMTime) -> OverlayPanelViewController.Model? {
        let sec = time.seconds
        let all = timeToSubtitleSubject.value
        guard
            let content = model.content,
            let nearestEnIndex = all.eng.firstIndex(where: { k, v in
                k >= sec && sec <= v.end.timeInSeconds
            })
        else {
            return nil
        }

        let thisItem: Networking.Subtitle = all.eng[nearestEnIndex].value
        var itemsBefore: [Networking.Subtitle] = []
        var itemsAfter: [Networking.Subtitle] = []

        if nearestEnIndex > 0 {
            let numItemsBefore = nearestEnIndex
            let lowerBoundIndex = nearestEnIndex.advanced(by: -min(numItemsBefore, 10))
            itemsBefore = Array(all.eng[lowerBoundIndex ..< nearestEnIndex].map(\.value))
        }

        let nextIndex = nearestEnIndex.advanced(by: 1)
        let numItemsAfter = all.eng.endIndex - nextIndex
        if numItemsAfter > 0 {
            let upperBoundIndex = nearestEnIndex.advanced(by: min(numItemsAfter, 10))
            itemsAfter = Array(all.eng[nextIndex ... upperBoundIndex].map(\.value))
        }

        func ruSubtitle(for en: Networking.Subtitle) -> Networking.Subtitle? {
            return all.ru.first { _, v in
                abs(v.start.timeInSeconds - en.start.timeInSeconds) <= 0.2
            }?.value
        }

        var subtitles: [OverlayPanelViewController.Model.Subtitle] = []
        subtitles.reserveCapacity(itemsBefore.count + itemsAfter.count + 1)
        itemsBefore.forEach { (en: Networking.Subtitle) in
            let model = OverlayPanelViewController.Model.Subtitle(
                en: en,
                ru: ruSubtitle(for: en),
                isActive: false
            )
            subtitles.append(model)
        }

        subtitles.append(
            OverlayPanelViewController.Model.Subtitle(
                en: thisItem,
                ru: ruSubtitle(for: thisItem),
                isActive: true
            )
        )

        itemsAfter.forEach { (en: Networking.Subtitle) in
            let model = OverlayPanelViewController.Model.Subtitle(
                en: en,
                ru: ruSubtitle(for: en),
                isActive: false
            )
            subtitles.append(model)
        }

        return OverlayPanelViewController.Model(
            movieName: content.movie.name,
            imageURL: URL(string: content.movie.photoURL).unsafelyUnwrapped,
            subtitles: subtitles
        )
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
}

private let trailerURL = URL(string: "https://strm.yandex.ru/vh-ott-converted/ott-content/530389814-4a54e1d887da77c3ab345f7635ca9b59/master.m3u8?from=ott-kp&hash=b60bc9cbe1e6783ff44e51c6568b8386&vsid=b9690d561690dbd1eff4bfe5c79a1b9304a4d904a019xWEBx6710x1629612671&video_content_id=4a54e1d887da77c3ab345f7635ca9b59&session_data=1&preview=1&t=1629612671617").unsafelyUnwrapped
