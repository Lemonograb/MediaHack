import AVKit
import Combine
import OverplayPanel_tvOS
import SharedCode
import UIKit

public final class PlayerViewController: BaseViewController {
    private let qrCodeImageView = UIImageView()
    private let interactor = PlayerInteractor()
    private var playerView: PlayerView!
    private var bag = Set<AnyCancellable>()
    private var playerObserverToken: Any?

    override public func setup() {
        qrCodeImageView.isHidden = true
        view.addSubview(qrCodeImageView)
        
        qrCodeImageView.pin(.leading).to(view).const(32).equal()
        qrCodeImageView.pin(.bottom).to(view).const(-32).equal()

        interactor.modelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] model in
                self.update(with: model)
            }.store(in: &bag)

        interactor.playerModelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] model in
                self.updatePlayer(with: model)
            }.store(in: &bag)

        interactor.adjustPlayerTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] time in
                self.playerView?.player.seek(to: time)
            }.store(in: &bag)

        interactor.qrCodePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] image in
                self.qrCodeImageView.image = image
                UIView.animate(withDuration: 0.3) {
                    self.qrCodeImageView.isHidden = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    UIView.animate(withDuration: 0.3) {
                        self.qrCodeImageView.isHidden = true
                    }
                }
            }.store(in: &bag)

        interactor.loadData().store(in: &bag)
        interactor.requestQRCode()

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handlePlayerTap))
        tapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        view.addGestureRecognizer(tapRecognizer)
    }

    private func update(with model: PlayerInteractor.Model) {
        if let error = model.error {
            print(error.localizedDescription)
        } else if let content = model.content {
            update(with: content)
        }
    }

    private func update(with content: PlayerInteractor.Model.Content) {
        playerView?.removeFromSuperview()
        playerObserverToken.flatMap { token in
            playerView?.player.removeTimeObserver(token)
        }

        playerView = PlayerView(
            model: PlayerView.Model(
                url: content.playerURL,
                subtitlesViewModel: SubtitlesView.Model(
                    onWordSelected: { [unowned self] _ in
                        self.playerView.isPlaying = false
                    }
                )
            )
        )
        view.insertSubview(playerView, at: 0)
        playerView.pinEdgesToSuperView()

        playerObserverToken = playerView.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .global(qos: .userInteractive)
        ) { [unowned self] offset in
            self.interactor.set(time: offset)
        }
        playerView.player.play()
    }

    private func updatePlayer(with model: PlayerInteractor.PlayerModel) {
        playerView?.subtitlesView.text = model.enSubtitle
    }

    @objc
    private func handlePlayerTap() {
        guard
            let playerView = playerView,
            let model = interactor.overlayModel(for: playerView.player.currentTime())
        else {
            return
        }
        guard playerView.isPlaying else {
            UIView.animate(withDuration: 0.3) { [self] in
                shadowView?.removeFromSuperview()
                shadowView = nil
                overlayViewController?.removeFromParent()
                overlayViewController = nil
            } completion: { _ in
                playerView.togglePlaying()
            }
            return
        }
        playerView.togglePlaying()
        interactor.set(playing: playerView.isPlaying)

        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        shadowView?.removeFromSuperview()
        view.addSubview(blurView)
        blurView.pinEdgesToSuperView()
        shadowView = blurView

        let controller = OverlayPanelViewController(model: model)
        addChild(controller)
        blurView.contentView.addSubview(controller.view)
        controller.view.backgroundColor = .clear
        controller.view.pinEdgesToSuperView()
        blurView.layoutIfNeeded()

        UIView.animate(withDuration: 0.3) { [self] in
            controller.update()
            overlayViewController = controller
        }
    }

    private var shadowView: UIView?
    private var overlayViewController: UIViewController?
}
