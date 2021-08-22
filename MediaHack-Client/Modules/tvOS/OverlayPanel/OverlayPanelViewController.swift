import Combine
import Networking
import Nuke
import SharedCode
import UIKit

open class FocusibleView: BaseView {
    override open var canBecomeFocused: Bool {
        return true
    }
}

open class FocusibleCollectionView: UICollectionView {
    override open var canBecomeFocused: Bool {
        return true
    }
}

public final class OverlayPanelViewController: BaseViewController {
    public struct Model {
        public struct Subtitle {
            public init(en: Networking.Subtitle?, ru: Networking.Subtitle?, isActive: Bool) {
                self.en = en
                self.ru = ru
                self.isActive = isActive
            }

            public let en: Networking.Subtitle?
            public let ru: Networking.Subtitle?
            public let isActive: Bool
        }

        public let movieName: String
        public let imageURL: URL
        public let subtitles: [Subtitle]

        public init(movieName: String, imageURL: URL, subtitles: [OverlayPanelViewController.Model.Subtitle]) {
            self.movieName = movieName
            self.imageURL = imageURL
            self.subtitles = subtitles
        }
    }

    private enum Section {
        case header, subtitles
    }

    private enum Item: Hashable {
        case header(HeaderCell.Model)
        case subtitle(SubtitleCell.Model)
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

    private let model: Model
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    public init(model: Model) {
        self.model = model
        self.collectionView = FocusibleCollectionView(frame: .zero, collectionViewLayout: OverlayPanelViewController.makeLayout())
        super.init()
    }

    override public func loadView() {
        view = FocusibleView()
        super.loadView()
    }

    override public func setup() {
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperView()
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: HeaderCell.reuseIdentifier)
        collectionView.register(SubtitleCell.self, forCellWithReuseIdentifier: SubtitleCell.reuseIdentifier)
    }

    public func update() {
        var selectedIndexPath: IndexPath?

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { cv, ip, model in
            switch model {
            case let .header(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: HeaderCell.reuseIdentifier, for: ip), to: HeaderCell.self)
                cell.configure(model: model)
                return cell
            case let .subtitle(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: SubtitleCell.reuseIdentifier, for: ip), to: SubtitleCell.self)
                cell.configure(model: model)
                if model.isActive {
                    selectedIndexPath = ip
                }
                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header, .subtitles])
        snapshot.appendItems(
            [
                .header(
                    HeaderCell.Model(
                        imageURL: model.imageURL,
                        movieName: model.movieName
                    )
                ),
            ],
            toSection: Section.subtitles
        )
        let subtitles = model.subtitles.flatMap { subtitle -> [Item] in
            var result: [Item] = []

            if let en = subtitle.en {
                let item = Item.subtitle(
                    SubtitleCell.Model(subtitle: WordsTokenizer.process(text: en.text), isActive: subtitle.isActive)
                )
                result.append(item)
            }
            if let ru = subtitle.ru {
                let item = Item.subtitle(
                    SubtitleCell.Model(
                        subtitle: ru.text.joined(separator: "\n").builder
                            .font(UIFont.systemFont(ofSize: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .result,
                        isActive: subtitle.isActive
                    )
                )
                result.append(item)
            }
            return result
        }
        snapshot.appendItems(subtitles, toSection: .subtitles)
        dataSource.apply(snapshot, animatingDifferences: true) {
            if let ip = selectedIndexPath {
                self.collectionView.scrollToItem(at: ip, at: .centeredVertically, animated: true)
            }
        }
    }
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

    override public var canBecomeFocused: Bool {
        return false
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
        let subtitle: NSAttributedString
        let isActive: Bool
    }

    override public var canBecomeFocused: Bool {
        return true
    }

    private let contentLabel = UILabel()

    override func setup() {
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.pinEdgesToSuperView()
    }

    func configure(model: Model) {
        contentLabel.attributedText = model.subtitle
        contentLabel.alpha = model.isActive ? 1 : 0.3
    }
}
