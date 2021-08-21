import Combine
import Nuke
import SharedCode
import UIKit

public final class SubtitlesOverlayViewController: BaseViewController {
    private enum Section {
        case header, subtitles
    }

    private enum Item: Hashable {
        case header(HeaderCell.Model)
        case subtitle(SubtitleCell.Model)
    }

    private struct Model: Hashable {
        let header: HeaderCell.Model
        let subtitles: [SubtitleCell.Model]
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

    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override public init() {
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: SubtitlesOverlayViewController.makeLayout())
        super.init()
    }

    override public func setup() {
        view.addSubview(collectionView)
        collectionView.pinEdgesToSuperView()
        collectionView.backgroundColor = #colorLiteral(red: 0.195160985, green: 0.2001810074, blue: 0.2427157164, alpha: 1)
        collectionView.register(HeaderCell.self, forCellWithReuseIdentifier: HeaderCell.reuseIdentifier)
        collectionView.register(SubtitleCell.self, forCellWithReuseIdentifier: SubtitleCell.reuseIdentifier)

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { cv, ip, model in
            switch model {
            case let .header(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: HeaderCell.reuseIdentifier, for: ip), to: HeaderCell.self)
                cell.configure(model: model)
                return cell
            case let .subtitle(model):
                let cell = unsafeDowncast(cv.dequeueReusableCell(withReuseIdentifier: SubtitleCell.reuseIdentifier, for: ip), to: SubtitleCell.self)
                cell.configure(model: model)
                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header, .subtitles])
        snapshot.appendItems(
            [
                .header(
                    HeaderCell.Model(
                        imageURL: URL(string: "https://cdn.service-kp.com/poster/item/big/392.jpg").unsafelyUnwrapped,
                        movieName: "Pulp fiction"
                    )
                ),
            ],
            toSection: Section.subtitles
        )
        snapshot.appendItems(
            [
                .subtitle(
                    SubtitleCell.Model(
                        subtitle: WordsTokenizer.process(
                            text: [
                                "Why do we feel it's necessary",
                                "to yak about bullshit in order to be comfortable",
                            ]
                        ),
                        isActive: false,
                        index: 0
                    )
                ),
                .subtitle(
                    SubtitleCell.Model(
                        subtitle: WordsTokenizer.process(
                            text: [
                                "Uncomfortable silences. Why do we feel it's necessary to yak about bullshit in order to be comfortable?",
                            ]
                        ),
                        isActive: true,
                        index: 1
                    )
                ),
                .subtitle(
                    SubtitleCell.Model(
                        subtitle: "Неловкое молчание. Почему людям обязательно нужно сморозить какую-нибудь чушь, лишь бы не почувствовать себя в своей тарелке?"
                            .builder
                            .font(UIFont.systemFont(ofSize: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .result,
                        isActive: true,
                        index: 2
                    )
                ),
                .subtitle(
                    SubtitleCell.Model(
                        subtitle: WordsTokenizer.process(
                            text: [
                                "Why do we feel it's necessary",
                                "to yak about bullshit in order to be comfortable",
                            ]
                        ),
                        isActive: false,
                        index: 3
                    )
                ),
            ],
            toSection: Section.subtitles
        )
        dataSource.apply(snapshot)
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
        let index: Int
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
