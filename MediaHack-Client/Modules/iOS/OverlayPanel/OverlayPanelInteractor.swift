import Combine
import Foundation
import Networking
import UIKit

final class OverlayPanelInteractor {
    typealias TimeToSubtitle = (key: Double, value: Networking.Subtitle)

    struct Model {
        struct Content {
            let movie: Networking.Movie
            let subtitles: [TimeToSubtitle]
        }

        var error: Error?
        var content: Content?
    }

    static let adjustment: Double = 0

    var model: Model {
        return modelSubject.value
    }

    var modelPublisher: AnyPublisher<Model, Never> {
        return modelSubject.eraseToAnyPublisher()
    }

    var playingTimePublisher: AnyPublisher<Double, Never> {
        return playingTimeSubject.eraseToAnyPublisher()
    }

    var definitionResult: AnyPublisher<[String], Never> {
        return definitionResultSubject.eraseToAnyPublisher()
    }

    var vc: UIViewController?

    private(set) var isPlaying = false

    private let modelSubject = CurrentValueSubject<Model, Never>(.init())
    private let playingTimeSubject = PassthroughSubject<Double, Never>()
    private let definitionResultSubject = PassthroughSubject<[String], Never>()

    init(wsID: String) {
        let decoder = JSONDecoder()
        WSManager.shared.connectToWebSocket(type: .phone, id: wsID)
        WSManager.shared.receiveData(completion: { [weak self] text in
            if
                let data = text.data(using: .utf8),
                let status = try? decoder.decode(WSStatus.self, from: data)
            {
                switch status {
                case .start, .stop, .playAt:
                    break
                case let .play(sec):
                    self?.isPlaying = true
                    self?.playingTimeSubject.send(sec)
                case .cancel:
                    self?.vc?.navigationController?.popViewController(animated: true)
                    WSManager.shared.cancel()
                }
            }
        })
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
            func iterate(over model: [Networking.Subtitle]) -> [TimeToSubtitle] {
                let model = model.sorted { s1, s2 in
                    s1.start.timeInSeconds < s2.start.timeInSeconds
                }
                var lowerboundToSubtitle: [TimeToSubtitle] = []
                lowerboundToSubtitle.reserveCapacity(model.count)
                for subtitle in model {
                    let adjustedKey = subtitle.start.timeInSeconds - OverlayPanelInteractor.adjustment
                    lowerboundToSubtitle.append((key: adjustedKey, value: subtitle))
                }
                return lowerboundToSubtitle
            }
            return Model(error: nil, content: Model.Content(movie: movie, subtitles: iterate(over: subtitles.en)))
        }
        .catch { (e: Error) -> Just<Model> in
            let model = Model(error: e, content: nil)
            return Just(model)
        }.subscribe(modelSubject)
    }

    func play(time: Double) {
        WSManager.shared.sendStatus(.playAt(sec: time - Self.adjustment))
        isPlaying = true
    }

    func pausePlay() {
        WSManager.shared.sendStatus(.stop)
        isPlaying = false
    }

    func togglePlay() {
        isPlaying ? pausePlay() : continuePlay()
        isPlaying.toggle()
        print("togglePlay", "=>", isPlaying)
    }

    func continuePlay() {
        WSManager.shared.sendStatus(.start)
        isPlaying = true
    }

    private var bag = Set<AnyCancellable>()
    func define(word: String) -> AnyPublisher<[String], Never> {
        pausePlay()
        print("define", word)
        return API.define(word: word)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
}
