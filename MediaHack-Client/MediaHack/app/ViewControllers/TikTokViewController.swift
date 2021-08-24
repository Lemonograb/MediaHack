import Combine
import CompositionalLayoutDSL
import Networking
import Nuke
import SharedCode
import UIKit

final class TikTokViewController: BaseViewController {
    private enum Section {
        case header, subtitles
    }

    private enum Item: Hashable {
        case word(WordCell.Model)
        case movie(MovieCell.Model)
        case song(SongCell.Model)
    }

    private static func makeLayout() -> CompositionalLayout {
        return CompositionalLayout { _, _ in
            CompositionalLayoutDSL.Section {
                VGroup {
                    CompositionalLayoutDSL.Item()
                        .width(.fractionalWidth(1))
                        .height(.absolute(80))

                    CompositionalLayoutDSL.Item()
                        .width(.fractionalWidth(1))
                        .height(.absolute(320))

                    CompositionalLayoutDSL.Item()
                        .width(.fractionalWidth(1))
                        .height(.absolute(248))
                }.interItemSpacing(.fixed(16))
            }
        }
    }

    private let collectionView: UICollectionView
    private let dataSource: UICollectionViewDiffableDataSource<Section, Item>
    private var bag = Set<AnyCancellable>()

    override init() {
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.setCollectionViewLayout(Self.makeLayout(), animated: false)
        self.dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { cv, ip, model in
            switch model {
            case let .word(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: WordCell.reuseIdentifier, for: ip), to: WordCell.self)
                cell.configure(model: model)
                return cell
            case let .movie(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseIdentifier, for: ip), to: MovieCell.self)
                cell.configure(model: model)
                return cell
            case let .song(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: SongCell.reuseIdentifier, for: ip), to: SongCell.self)
                cell.configure(model: model)
                return cell
            }
        }
        super.init()

        collectionView.register(WordCell.self, forCellWithReuseIdentifier: WordCell.reuseIdentifier)
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseIdentifier)
        collectionView.register(SongCell.self, forCellWithReuseIdentifier: SongCell.reuseIdentifier)
        collectionView.dataSource = dataSource
        collectionView.showsVerticalScrollIndicator = false
    }

    private var subtitles: [Subtitle] = []

    override func setup() {
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        API.getMovies()
            .flatMap { movies in
                API.getSubtitle(movie: movies[0])
                    .map { subtitles in
                        (movies, subtitles)
                    }
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] movies, subtitles in
                    self?.update(with: movies[0], subtitles: subtitles)
                }
            )
            .store(in: &bag)
    }

    private func subtitle(for time: CMTime) -> Subtitle? {
        return subtitles.first { s in
            if s.end.timeInSeconds < time.seconds {
                return false
            }
            return s.start.timeInSeconds <= time.seconds && s.end.timeInSeconds >= time.seconds
        }
    }

    private func update(with movie: Movie, subtitles: MovieSubtitles) {
        self.subtitles = subtitles.en

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header])
        snapshot.appendItems([
            .word(.init(word: "Quarter Pounder")),
            .movie(
                .init(
                    url: URL(string: movie.url).unsafelyUnwrapped,
                    tokenTime: { () -> Double in
                        let fallback: Double = 221
                        if
                            let st = subtitles.en.first(where: { s in
                                s.text.contains { str in
                                    str.lowercased().contains("Quarter-Pounder".lowercased())
                                }
                            })
                        {
                            return Double(Int(st.start.timeInSeconds - 1))
                        } else {
                            return fallback
                        }
                    }(),
                    callback: MovieCell.Model.Callback(
                        onTick: { [weak self] time, cell in
                            if let s = self?.subtitle(for: time) {
                                cell.update(with: s)
                            }
                        }
                    )
                )
            ),
            .song(
                .init(
                    iconURL: URL(string: "https://images.genius.com/4a9ce06a1f463b0c24c98c1870d4566f.1000x1000x1.png").unsafelyUnwrapped,
                    songName: "The ringer",
                    text: [
                        "I guess when you walk into BK you expect a Whopper",
                        "You can order a Quarter Pounder when you go to McDonald's",
                        "But if you're lookin' to get a porterhouse you better go get Revival",
                        "But y'all are actin' like I tried to serve you up a slider",
                    ]
                )
            ),
        ])
        dataSource.apply(snapshot)
    }
}

final class WordCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let word: String
    }

    private let contentLabel = UILabel()

    func configure(model: Model) {
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.pin(.top).to(contentView).const(24).equal()
        contentLabel.pin(.leading).to(contentView).const(24).equal()
        contentLabel.pin(.trailing).to(contentView).const(-8).lessThanOrEqual()

        contentLabel.attributedText = model.word.builder
            .font(UIFont.systemFont(ofSize: 32, weight: .bold))
            .alignment(.center)
            .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1)).result
    }
}

final class MovieCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let url: URL
        let tokenTime: Double
        let callback: Callback

        struct Callback: Hashable {
            static func == (lhs: MovieCell.Model.Callback, rhs: MovieCell.Model.Callback) -> Bool {
                return true
            }

            func hash(into hasher: inout Hasher) {}

            let onTick: (CMTime, MovieCell) -> Void
        }
    }

    private var player: PlayerView?
    private var playerObserverToken: Any?

    override func prepareForReuse() {
        super.prepareForReuse()
        playerObserverToken.flatMap { token in
            player?.player.removeTimeObserver(token)
            self.playerObserverToken = nil
        }
        player?.player.pause()
        player?.removeFromSuperview()
    }

    override func setup() {}

    func configure(model: Model) {
        player?.removeFromSuperview()

        let player = PlayerView(model: .init(url: model.url))
        contentView.addSubview(player)
        player.pinEdgesToSuperView()
        self.player = player
        player.player.play()

        let sec = CMTime(seconds: model.tokenTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.player.seek(to: sec, toleranceBefore: .zero, toleranceAfter: .zero)

        player.layer.cornerRadius = 6
        player.clipsToBounds = true

        playerObserverToken.flatMap { token in
            player.player.removeTimeObserver(token)
            self.playerObserverToken = nil
        }

        playerObserverToken = player.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            model.callback.onTick(time, self)
        }
    }

    func update(with subtitle: Subtitle) {
        let text = subtitle.text
        let tokens = WordsTokenizer.process(text: text, whiteList: Set<String>(["Quarter-Pounder"]), whiteListLines: Set<String>(["Quarter-Pounder"]))
        player?.subtitlesView.text = tokens
    }
}

final class SongCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let iconURL: URL
        let songName: String
        let text: [String]
    }

    private let songImage = UIImageView()
    private let contentLabel = UILabel()
    private let textLabel = UILabel()

    override func setup() {
        contentView.addSubview(songImage)
        contentView.addSubview(contentLabel)
        contentView.addSubview(textLabel)
        contentView.backgroundColor = .white

        contentView.layer.cornerRadius = 4
        contentView.clipsToBounds = true

        songImage.layer.cornerRadius = 4
        songImage.clipsToBounds = true

        contentLabel.numberOfLines = 0
        textLabel.numberOfLines = 0
    }

    func configure(model: Model) {
        Nuke.loadImage(with: model.iconURL, into: songImage)
        contentLabel.attributedText = model.songName.builder
            .font(UIFont.systemFont(ofSize: 18, weight: .medium))
            .foregroundColor(UIColor.black)
            .result

        songImage.pin(.top).to(contentView).const(8).equal()
        songImage.pin(.leading).to(contentView).const(8).equal()
        songImage.pin(.width).const(72).equal()
        songImage.pin(.height).const(72).equal()

        contentLabel.pin(.top).to(songImage).const(2).equal()
        contentLabel.pin(.left).to(songImage, .right).const(4).equal()
        contentLabel.pin(.right).to(contentView).const(16).lessThanOrEqual()

        textLabel.pin(.top).to(songImage, .bottom).const(24).equal()
        textLabel.pin(.left).to(songImage).equal()
        textLabel.pin(.right).to(contentView).lessThanOrEqual()

        let result = NSMutableAttributedString()
        for (i, line) in model.text.enumerated() {
            if line.contains("Quarter Pounder") {
                for word in line.split(separator: " ") {
                    let s = String(word)

                    let whitelist = Set<String>(["quarter", "pounder"])
                    if whitelist.contains(s.lowercased()) {
                        let part = "\(s)\(String.nbsp)".builder
                            .font(UIFont.systemFont(ofSize: 16))
                            .foregroundColor(#colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1)).result
                        result.append(part)
                    } else {
                        let part = "\(s)\(String.nbsp)".builder
                            .font(UIFont.systemFont(ofSize: 16))
                            .foregroundColor(.black).result
                        result.append(part)
                    }
                }
            } else {
                let part = line.builder
                    .font(UIFont.systemFont(ofSize: 16))
                    .foregroundColor(.black).result
                result.append(part)
            }
            if i != model.text.endIndex - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        textLabel.attributedText = result
    }
}

import AVKit

final class PlayerView: BaseView {
    struct Model {
        let url: URL
    }

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    let player: AVPlayer
    let subtitlesView: SubtitlesView

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    var isPlaying: Bool {
        get { !player.rate.isZero && player.error == nil }
        set {
            newValue ? player.play() : player.pause()
            pauseIcon.isHidden = newValue
        }
    }

    private let pauseIcon = UIImageView(image: UIImage(named: "ic_pause"))

    init(model: Model) {
        self.player = AVPlayer(url: model.url)
        self.subtitlesView = SubtitlesView()
        super.init(frame: .zero)
    }

    override func setup() {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        pauseIcon.isHidden = true
        addSubview(pauseIcon)
        pauseIcon.pinCenter(to: self)

        addSubview(subtitlesView)
        subtitlesView.pin(.centerX).to(safeAreaLayoutGuide, .centerX).equal()
        subtitlesView.pin(.bottom).to(safeAreaLayoutGuide, .bottom).const(-24).equal()
        subtitlesView.pin(.left).to(safeAreaLayoutGuide, .left).const(24).greaterThanOrEqual()
        subtitlesView.pin(.right).to(safeAreaLayoutGuide, .right).const(-24).lessThanOrEqual()
        subtitlesView.setupLayout()
    }

    func togglePlaying() {
        isPlaying = !isPlaying
    }
}

final class SubtitlesView: BaseView {
    var text: NSAttributedString? {
        get { return contentLabel.attributedText }
        set { contentLabel.attributedText = newValue }
    }

    private var definitionView: UIView?
    private let contentLabel = UILabel()

    override func setup() {
        contentLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        contentLabel.textColor = .label
        layer.cornerRadius = 4
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping

        backgroundColor = #colorLiteral(red: 0.195160985, green: 0.2001810074, blue: 0.2427157164, alpha: 1).withAlphaComponent(0.85)
        addSubview(contentLabel)
    }

    func setupLayout() {
        let insets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        contentLabel.pinToSuperView(.top).const(insets.top).equal()
        contentLabel.pinToSuperView(.left).const(insets.left).equal()
        contentLabel.pinToSuperView(.bottom).const(-insets.bottom).equal()
        contentLabel.pinToSuperView(.right).const(-insets.right).equal()
    }
}
