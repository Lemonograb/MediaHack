import AVKit
import SharedCode
import UIKit

final class PlayerView: BaseView {
    struct Model {
        let url: URL
        let subtitlesViewModel: SubtitlesView.Model
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
        self.subtitlesView = SubtitlesView(model: model.subtitlesViewModel)
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc
    private func handleTap() {
        isPlaying = !isPlaying
    }
}

// https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/observing_the_playback_time
