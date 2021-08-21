import AVKit
import SharedCode
import UIKit

final class PlayerView: BaseView {
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    let player = AVPlayer(url: videoURL)
    let subtitlesView = SubtitlesView()

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override func setup() {
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        addSubview(subtitlesView)
        subtitlesView.pin(.centerX).to(safeAreaLayoutGuide, .centerX).equal()
        subtitlesView.pin(.bottom).to(safeAreaLayoutGuide, .bottom).const(-24).equal()
        subtitlesView.pin(.left).to(safeAreaLayoutGuide, .left).const(24).greaterThanOrEqual()
        subtitlesView.pin(.right).to(safeAreaLayoutGuide, .right).const(-24).lessThanOrEqual()
        subtitlesView.setupLayout()
    }
}

// https://developer.apple.com/documentation/avfoundation/media_playback_and_selection/observing_the_playback_time
