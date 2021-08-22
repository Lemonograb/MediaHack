import AVKit
import Combine
import Foundation
import Networking

final class PlayerInteractor {
    struct Model {
        let movie: Networking.Movie
        let subtitles: Networking.MovieSubtitles
    }
    
    let playerTimeSubject = PassthroughSubject<CMTime, Never>()
    let playingStatusSubject = PassthroughSubject<Bool, Never>()
    
    var playingStatusPublisher: AnyPublisher<Bool, Never> {
        return playingStatusSubject.eraseToAnyPublisher()
    }
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        WSManager.shared.connectToWebSocket(type: .tv, id: nil)
        playingStatusSubject.sink { isPlaying in
            WSManager.shared.sendStatus(isPlaying ? .start : .stop)
        }.store(in: &bag)
        
        playerTimeSubject.sink { time in
            WSManager.shared.sendStatus(.play(sec: time.seconds))
        }.store(in: &bag)
    }

    func loadData() -> AnyPublisher<Model, Error> {
        return API.getMovies().map { list in
            list[0]
        }.flatMap { movie in
            API.getSubtitle(movie: movie).map { subtitles in
                (movie, subtitles)
            }
        }.map { movie, subtitles -> Model in
            Model(movie: movie, subtitles: subtitles)
        }.eraseToAnyPublisher()
    }
}
