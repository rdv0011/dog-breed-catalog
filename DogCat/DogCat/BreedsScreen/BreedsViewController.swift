//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import UIKit
import Combine

/// Is used to inform [BreedsViewCoordinator](x-source-tag://BreedsViewCoordinator) about user actions that may lead to transition to another screen
protocol BreedsViewControllerDelegate: AnyObject {
    /// User selected a specific breed name
    func breedSelected(breedName: String)
    /// User pressed the favourites button
    func favoritesPressed()
}

/// Represents the screen with Breed names list
class BreedsViewController: UIViewController {
    // MARK: - Type Aliases
    typealias DataSource = UICollectionViewDiffableDataSource<BreedsViewModel.DataSection, BreedsViewModel.DataObject>

    // MARK: - Public vars
    // It suppose to report to a corresponding coordinator to do transition to another view controller
    weak var delegate: BreedsViewControllerDelegate?

    // MARK: - Private vars
    private let breedsViewModel: BreedsViewModel

    private lazy var breedsCollectionView: UICollectionView = {
        makeUICollectionView()
    }()

    private lazy var noDataLabel = UILabel().then {
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }

    private lazy var favoritesButton = UIBarButtonItem(
        title: Localized.breedNamesFavoritesButtonTitle,
        style: .plain,
        target: self,
        action: #selector(favoritesPressed)
    )
    private lazy var refreshingControl = UIRefreshControl().then {
        $0.tintColor = .systemGray
    }

    private lazy var collectionViewDataSource = {
        makeCollectionViewDataSource(for: breedsCollectionView)
    }()
    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: BreedsViewModel) {
        self.breedsViewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        configureViews()
        configureLayout()
        subscribe()
    }

    private func configureViews() {
        navigationItem.rightBarButtonItem = favoritesButton
        title = breedsViewModel.title
        view.addSubview(breedsCollectionView)
        view.addSubview(noDataLabel)
    }

    private func configureLayout() {
        breedsCollectionView.fillSuperview()
        noDataLabel.fillSuperview()
    }

    private func subscribe() {
        subscriptions.add([
        breedsViewModel
            .$snapshot
            .executeOnMain(collectionViewDataSource.apply),
        breedsViewModel
            .isNoDataLabelHidden
            .weakAssignOnMain(to: \.isHidden, on: noDataLabel),
        breedsViewModel
            .noDataLabelText
            .weakAssignOnMain(to: \.text, on: noDataLabel),
        breedsViewModel
            .isFavoritesButtonEnabled
            .weakAssignOnMain(to: \.isEnabled, on: favoritesButton),
        breedsViewModel
            .isContentRefreshing
            .executeOnMain(refreshingControl.updateRefreshing),
        refreshingControl
            .beginRefreshingPublisher
            .weakAssign(to: \.beginRefreshing, on: breedsViewModel)
        ])
    }

    private func makeUICollectionView() -> UICollectionView {
        // And create the UICollection View
        UICollectionView(frame: .zero,
                         collectionViewLayout: CollectionViewLayoutFactory().makeBreedsCollectionViewLayout()).then {
            // Register a cell
            $0.register(BreedsCollectionViewCell.self)
            $0.delegate = self
            $0.refreshControl = refreshingControl
            $0.backgroundColor = .systemBackground
        }
    }

    @objc
    private func favoritesPressed() {
        delegate?.favoritesPressed()
    }

    private func makeCollectionViewDataSource(for collectionView: UICollectionView) -> DataSource {
        DataSource(collectionView: collectionView) { [unowned self] (collectionView, indexPath, data) -> UICollectionViewCell? in
            let breedNameCell: BreedsCollectionViewCell = collectionView
                .dequeueReusableCell(for: indexPath)
            self.configure(cell: breedNameCell, with: data)
            return breedNameCell
        }
    }

    private func configure(cell: BreedsCollectionViewCell, with breedName: BreedsViewModel.DataObject) {
        cell.breedNameLabel.text = breedName.capitalizingFirstLetter()
        cell.imageDownloadingSubscription = breedsViewModel
            .image(for: breedName, activityAnimating: cell.activityIndicator)
            .weakAssign(to: \.image, on: cell.imageView)
    }
}

extension BreedsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedBreedName = collectionViewDataSource.itemIdentifier(for: indexPath) else {
            return
        }
        delegate?.breedSelected(breedName: selectedBreedName)
    }
}
