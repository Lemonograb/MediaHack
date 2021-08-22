import Combine
import Foundation
import Networking

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

    static let adjustment: Double = 2589.5

    var model: Model {
        return modelSubject.value
    }

    var modelPublisher: AnyPublisher<Model, Never> {
        return modelSubject.eraseToAnyPublisher()
    }

    var playingTimePublisher: AnyPublisher<Double, Never> {
        return playingTimeSubject.eraseToAnyPublisher()
    }

    private let modelSubject = CurrentValueSubject<Model, Never>(.init())
    private let playingTimeSubject = PassthroughSubject<Double, Never>()

    init() {
        let decoder = JSONDecoder()
        WSManager.shared.connectToWebSocket(type: .phone, id: "test")
        WSManager.shared.receiveData(completion: { [weak self] text in
            if
                let data = text.data(using: .utf8),
                let status = try? decoder.decode(WSStatus.self, from: data)
            {
                switch status {
                case .start, .stop, .playAt:
                    break
                case let .play(sec):
                    self?.playingTimeSubject.send(sec)
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
    }
}
