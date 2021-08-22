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

    private let interactor: OverlayPanelInteractor
    private let collectionView: UICollectionView
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var bag = Set<AnyCancellable>()

    private var lastActiveIndexPath: IndexPath?
    private unowned var cellRequestedDefinition: SubtitleCell?

    public init(wsID: String) {
        self.interactor = OverlayPanelInteractor(wsID: wsID)
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
                            if result.isEmpty {
                                self.cellRequestedDefinition?.removeDefinition()
                            } else {
                                self.cellRequestedDefinition?.show(definition: result)
                            }
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
}
