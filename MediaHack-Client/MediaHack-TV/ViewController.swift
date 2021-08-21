import AVKit
import SharedCode
import UIKit
import Networking

// https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/observing_the_playback_time

private let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4").unsafelyUnwrapped

final class SubtitlesView: UIView {
    private let contentLabel = UILabel()

    var text: String? {
        get { return contentLabel.text }
        set { contentLabel.text = newValue }
    }

    func setup() {
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.textColor = .label
        layer.cornerRadius = 6
        contentLabel.numberOfLines = 0

        backgroundColor = .black
        addSubview(contentLabel)

        let inset: CGFloat = 8
        contentLabel.pinToSuperView(.top).const(inset).equal()
        contentLabel.pinToSuperView(.left).const(inset).equal()
        contentLabel.pinToSuperView(.bottom).const(-inset).equal()
        contentLabel.pinToSuperView(.right).const(-inset).equal()
        text = "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English."
    }
}

final class PlayerView: UIView {
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    let player = AVPlayer(url: videoURL)
    let subtitlesView = SubtitlesView()

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    func setup() {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        addSubview(subtitlesView)
        subtitlesView.pin(.bottom).to(safeAreaLayoutGuide, .bottom).const(-16).equal()
        subtitlesView.pin(.left).to(safeAreaLayoutGuide, .left).const(16).equal()
        subtitlesView.pin(.right).to(safeAreaLayoutGuide, .right).const(-16).equal()
        subtitlesView.setup()
    }
}

class ViewController: UIViewController {
    private let playerView = PlayerView()
    private let labels = [
        "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English.",
        "Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for 'lorem ipsum' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).",
        "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable.",
        "If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet.",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        WSManager.shared.connectToWebSocket(type: .tv, id: "tv")
        WSManager.shared.sendStatus(.start)
        WSManager.shared.receiveData(completion: { text in
            if let data = text.data(using: .utf8),
               let status = try? JSONDecoder().decode(WSStatus.self, from: data) {
                switch status {
                case .start:
                    self.playerView.player.play()
                case .stop:
                    self.playerView.player.pause()
                case .play(let sec):
                    break
                }
            }
        })
        playerView.setup()
        view.addSubview(playerView)
        playerView.pinEdgesToSuperView()

        playerView.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [unowned self] offset in
            let sec = Int(offset.seconds)
            WSManager.shared.sendStatus(.play(sec: sec))
            let label = self.labels[sec % self.labels.count]
            self.playerView.subtitlesView.text = label
        }
        playerView.player.play()
    }
}
