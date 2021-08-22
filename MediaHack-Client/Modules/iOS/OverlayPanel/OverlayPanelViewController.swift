import Combine
import Networking
import Nuke
import SharedCode
import UIKit

public final class OverlayPanelViewController: BaseViewController, UICollectionViewDelegate {
    struct Model {
        struct Subtitle: Hashable {
            let en: [String]
            let index: Int
            let isActive: Bool
        }

        let movieName: String
        let imageURL: URL
        let subtitles: [Subtitle]
    }

    private enum Section {
        case header, subtitles
    }

    private enum Item: Hashable {
        case header(HeaderCell.Model)
        case subtitle(Model.Subtitle)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(36)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets.top = 28
                if Device.isPhone {
                    section.contentInsets.leading = 12
                    section.contentInsets.trailing = 12
                } else {
                    section.contentInsets.leading = 64
                    section.contentInsets.trailing = 64
                }
                return section
            }

            let size = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(36)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: nil, top: .fixed(12),
                trailing: nil, bottom: .fixed(12)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets.top = 12
            if Device.isPhone {
                section.contentInsets.leading = 24
                section.contentInsets.trailing = 24
            } else {
                section.contentInsets.leading = 80
                section.contentInsets.trailing = 120
            }
            section.contentInsets.bottom = 12
            return section
        }
        return layout
    }

    private let interactor = OverlayPanelInteractor()
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var bag = Set<AnyCancellable>()

    private unowned var cellRequestedDefinition: SubtitleCell?

    override public init() {
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: OverlayPanelViewController.makeLayout())
        super.init()

        collectionView.delegate = self
        interactor.loadData().store(in: &bag)
        interactor.playingTimePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] time in
                self.update(with: time)
            }.store(in: &bag)
        interactor.definitionResult
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] result in
                if result.isEmpty {
                    self.interactor.continuePlay()
                } else {
                    self.cellRequestedDefinition?.show(definition: result)
                }
            }.store(in: &bag)
    }

    override public func setup() {
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperView()
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: HeaderCell.reuseIdentifier)
        collectionView.register(SubtitleCell.self, forCellWithReuseIdentifier: SubtitleCell.reuseIdentifier)
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { [unowned self] cv, ip, model in
            switch model {
            case let .header(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: HeaderCell.reuseIdentifier, for: ip), to: HeaderCell.self)
                cell.configure(model: model)
                return cell
            case let .subtitle(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: SubtitleCell.reuseIdentifier, for: ip), to: SubtitleCell.self)
                cell.configure(model: SubtitleCell.Model(text: WordsTokenizer.process(text: model.en), isActive: model.isActive))
                cell.onWordSelected = { [unowned self] word in
                    if let prev = self.cellRequestedDefinition, prev !== cell {
                        _ = prev.removeDefinition()
                    }
                    self.cellRequestedDefinition = cell
                    self.interactor
                        .define(word: word)
                        .receive(on: DispatchQueue.main)
                        .sink { [unowned self] result in
                            self.cellRequestedDefinition?.show(definition: result)
                        }.store(in: &self.bag)
                }
                return cell
            }
        }
        view.addGestureRecognizer { [unowned self] (_: UITapGestureRecognizer) in
            if let cell = cellRequestedDefinition, cell.removeDefinition() {
                self.interactor.continuePlay()
                self.cellRequestedDefinition = nil
            }
        }
    }

    private var gotCode = false
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !gotCode else {
            return
        }
        gotCode = true
        let c = ScannerViewController()
        present(c, animated: true)
        c.onCode = { wsId in
            if UUID(uuidString: wsId) != nil {
                self.interactor.startWS(id: wsId)
            }
            c.dismiss(animated: true, completion: nil)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let content = interactor.model.content {
            let startSecond = content.subtitles[indexPath.row - 1].value.start.timeInSeconds
            interactor.play(time: startSecond)
        }
    }

    private func update(with time: Double) {
        guard let content = interactor.model.content else {
            return
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header, .subtitles])
        snapshot.appendItems(
            [
                .header(
                    HeaderCell.Model(
                        imageURL: URL(string: content.movie.photoURL).unsafelyUnwrapped,
                        movieName: content.movie.name
                    )
                ),
            ],
            toSection: Section.subtitles
        )
        let subtitlesModels = content.subtitles.enumerated().map { (i, tuple: OverlayPanelInteractor.TimeToSubtitle) -> Model.Subtitle in
            let adjustedSec: Double = time + OverlayPanelInteractor.adjustment
            let isActive: Bool
            if tuple.value.end.timeInSeconds < adjustedSec {
                isActive = false
            } else {
                isActive = tuple.value.start.timeInSeconds <= adjustedSec && adjustedSec <= tuple.value.end.timeInSeconds
            }
            return Model.Subtitle(en: tuple.value.text, index: i, isActive: isActive)
        }
        let subtitles = subtitlesModels.map { model -> Item in
            .subtitle(model)
        }
        let activeIndex = subtitlesModels.firstIndex(where: \.isActive)
        let activeIndexPath = activeIndex.flatMap { index in
            IndexPath(row: index, section: 1)
        }

        snapshot.appendItems(subtitles, toSection: .subtitles)
        dataSource.apply(snapshot, animatingDifferences: true) {
            if let activeIndexPath = activeIndexPath {
                self.collectionView.scrollToItem(at: activeIndexPath, at: .centeredVertically, animated: true)
                self.lastActiveIndexPath = activeIndexPath
            }
        }
    }

    private var lastActiveIndexPath: IndexPath?
}

open class BaseCollectionViewCell: UICollectionViewCell {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        return nil
    }

    open func setup() {}
}

final class HeaderCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let imageURL: URL
        let movieName: String
    }

    private let imageView = UIImageView()
    private let contentLabel = UILabel()

    override func setup() {
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = #colorLiteral(red: 0.8695564866, green: 0.5418210626, blue: 0, alpha: 1)
        imageView.layer.cornerRadius = 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        contentView.addSubview(imageView)

        imageView.pin(.top).to(self).const(4).equal()
        imageView.pin(.leading).to(self).const(4).equal()
        imageView.pin(.centerY).to(self).equal()
        imageView.pinSize(square: 28)

        contentView.addSubview(contentLabel)
        contentLabel.pin(.leading).to(imageView, .trailing).const(8).equal()
        contentLabel.pin(.trailing).to(self).lessThanOrEqual()
        contentLabel.pin(.centerY).to(imageView).equal()
    }

    func configure(model: Model) {
        Nuke.loadImage(with: model.imageURL, into: imageView)
        contentLabel.attributedText = model.movieName.builder
            .font(UIFont.systemFont(ofSize: 15, weight: .semibold))
            .foregroundColor(.white).result
    }
}

final class SubtitleCell: BaseCollectionViewCell, ReuseIdentifiable, Configurable {
    struct Model: Hashable {
        let text: NSAttributedString
        let isActive: Bool
    }

    var onWordSelected: ((String) -> Void)?
    private let contentLabel = UILabel()

    override func setup() {
        contentLabel.numberOfLines = 0
        contentLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(contentLabel)
        contentLabel.pinEdgesToSuperView()

        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap(_:)))
        longTap.minimumPressDuration = 0.35
        contentView.addGestureRecognizer(longTap)
    }

    func configure(model: Model) {
        contentLabel.attributedText = model.text
        contentLabel.alpha = model.isActive ? 1 : 0.3
    }

    private var selectedWord: String?
    private var lastTouchLocation: CGPoint?
    private var tooltip: ToolTipView?

    func show(definition: [String]) {
        UIView.animate(withDuration: 0.3) {
            self.tooltip?.removeFromSuperview()
        }
        if let word = selectedWord, let location = lastTouchLocation {
            let tooltip = ToolTipView(word: word, definition: definition)
            contentView.addSubview(tooltip)
            tooltip.bounds.size.width = 228
            tooltip.bounds.size.height = 64
            tooltip.cornerRadius = 6
            tooltip.fillColor = #colorLiteral(red: 1, green: 0.6687215567, blue: 0, alpha: 1).withAlphaComponent(0.96)
            tooltip.strokeColor = .clear
            tooltip.lineWidth = 0
            tooltip.backgroundColor = .clear
            tooltip.layoutIfNeeded()
            tooltip.alpha = 0
            tooltip.frame.origin.x = location.x - (tooltip.bounds.size.width / 2)
            tooltip.frame.origin.y = location.y - tooltip.bounds.height
            UIView.animate(withDuration: 0.3) {
                tooltip.alpha = 1
            }
            self.tooltip = tooltip
        }
    }

    func removeDefinition() -> Bool {
        guard let view = tooltip else {
            return false
        }
        UIView.animate(withDuration: 0.3) {
            view.removeFromSuperview()
        }
        selectedWord = nil
        lastTouchLocation = nil
        return true
    }

    @objc
    private func handleLongTap(_ r: UILongPressGestureRecognizer) {
        guard let chIndex = r.tappedCharacterIndex(label: contentLabel), r.state == .began else {
            return
        }
        lastTouchLocation = r.location(in: contentView)

        let plain = contentLabel.attributedText.unsafelyUnwrapped.string
        var lowerBoundIndex = plain.index(plain.startIndex, offsetBy: chIndex)
        var upperBoundIndex = plain.index(plain.startIndex, offsetBy: chIndex)

        let indices = plain.indices
        var allowedSet = CharacterSet.letters
        allowedSet.formUnion(CharacterSet(charactersIn: "'"))

        for idx in plain.indices[indices.startIndex ..< lowerBoundIndex].reversed() {
            if CharacterSet(charactersIn: String(plain[idx])).isSubset(of: allowedSet) {
                lowerBoundIndex = idx
            } else {
                break
            }
        }
        for idx in plain.indices[upperBoundIndex ..< indices.endIndex] {
            if CharacterSet(charactersIn: String(plain[idx])).isSubset(of: allowedSet) {
                upperBoundIndex = idx
            } else {
                break
            }
        }
        let str = String(plain[lowerBoundIndex ... upperBoundIndex])
        selectedWord = str
        onWordSelected?(str)
    }
}

import AVFoundation
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCode: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }

    func found(code: String) {
        onCode?(code)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension UILongPressGestureRecognizer {
    func tappedCharacterIndex(label: UILabel) -> Int? {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText.unsafelyUnwrapped)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)

        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        if !textBoundingBox.contains(locationOfTouchInTextContainer) {
            return nil
        }

        return layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }
}

private final class ToolTipView: BaseView {
    private var shapeLayer: CALayer?
    private let wordLabel = UILabel()
    private let definitionLabel = UILabel()
    private let iconImageView = UIImageView(image: UIImage(named: "ic_plus"))

    var lineWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    var cornerRadius: CGFloat = 4 { didSet { setNeedsDisplay() } }
    var calloutSize: CGFloat = 8 { didSet { setNeedsDisplay() } }
    var fillColor: UIColor = .clear { didSet { setNeedsDisplay() } }
    var strokeColor: UIColor = .clear { didSet { setNeedsDisplay() } }

    init(word: String, definition: [String]) {
        super.init()
        addSubview(wordLabel)
        addSubview(definitionLabel)
        addSubview(iconImageView)

        wordLabel.attributedText = word.capitalized.builder
            .font(UIFont.systemFont(ofSize: 13, weight: .medium))
            .foregroundColor(#colorLiteral(red: 0.1960550249, green: 0.1960947812, blue: 0.1960498393, alpha: 1)).result

        wordLabel.pin(.height).const(18).equal()
        wordLabel.pin(.top).to(self).const(8).equal()
        wordLabel.pin(.left).to(self).const(8).equal()

        definitionLabel.pin(.height).const(18).equal()
        definitionLabel.pin(.top).to(wordLabel, .bottom).equal()
        definitionLabel.pin(.left).to(self).const(8).equal()

        iconImageView.pin(.width).const(16).equal()
        iconImageView.pin(.height).const(16).equal()
        iconImageView.pin(.top).to(self).const(8).equal()
        iconImageView.pin(.right).to(self).const(-8).equal()

        definitionLabel.attributedText = definition[0].capitalized.builder
            .font(UIFont.systemFont(ofSize: 13, weight: .bold))
            .foregroundColor(.white).result
    }

    override func draw(_ rect: CGRect) {
        let rect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        let path = UIBezierPath()

        // lower left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - calloutSize))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - calloutSize - cornerRadius),
            controlPoint: CGPoint(x: rect.minX, y: rect.maxY - calloutSize)
        )

        // left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

        // upper left corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            controlPoint: CGPoint(x: rect.minX, y: rect.minY)
        )

        // top
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))

        // upper right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            controlPoint: CGPoint(x: rect.maxX, y: rect.minY)
        )

        // right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize - cornerRadius))

        // lower right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - calloutSize),
            controlPoint: CGPoint(x: rect.maxX, y: rect.maxY - calloutSize)
        )

        // bottom (including callout)
        path.addLine(to: CGPoint(x: rect.midX + calloutSize, y: rect.maxY - calloutSize))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - calloutSize, y: rect.maxY - calloutSize))
        path.close()

        fillColor.setFill()
        path.fill()

        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}
