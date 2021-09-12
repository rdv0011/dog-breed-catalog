//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit
import Combine

/// Represents both screens Breed Images and Favorites
///
/// The reason why these two screen combined is that they have similar design and functionality
class BreedImagesViewController: UIViewController {
    // MARK: - Type Aliases
    typealias DataSource = UICollectionViewDiffableDataSource<BreedImagesViewModel.DataSection, BreedImagesViewModel.DataObject>

    // MARK: - Private vars
    private let breedImagesViewModel: BreedImagesViewModel

    private lazy var breedImagesCollectionView: UICollectionView = {
        makeUICollectionView()
    }()
    private lazy var collectionViewDataSource = {
        makeCollectionViewDataSource(for: breedImagesCollectionView)
    }()
    private var subscriptions = Set<AnyCancellable>()

    private lazy var searchResultViewController =
        SearchResultsTableViewController(cellConfigurator: TableViewCellStringConfigurator())

    private lazy var searchController = UISearchController(searchResultsController: searchResultViewController).then {
        $0.searchBar.placeholder = Localized.favoritesSearchBarPlaceholder
        $0.hidesNavigationBarDuringPresentation = true
        $0.showsSearchResultsController = true
    }

    private lazy var noDataLabel = UILabel().then {
        $0.isHidden = true
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }

    private lazy var refreshingControl = UIRefreshControl().then {
        $0.tintColor = .systemGray
    }

    init(viewModel: BreedImagesViewModel) {
        self.breedImagesViewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    deinit {
        log.verbose(.breedImages, "Deinit \(BreedImagesViewController.self)")
    }

    override func viewDidLoad() {
        configureViews()
        configureLayout()
        subscribe()
    }

    private func configureViews() {
        title = breedImagesViewModel.title
        breedImagesCollectionView.isAutoLayout = true
        view.addSubview(breedImagesCollectionView)
        view.addSubview(noDataLabel)
        if breedImagesViewModel.showSearchBar {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            definesPresentationContext = true
            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
        }
    }

    private func configureLayout() {
        NSLayoutConstraint.activate([
            breedImagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor
            ),
            breedImagesCollectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            breedImagesCollectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            breedImagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        )
        noDataLabel.fillSuperview()
    }

    private func visibleItems() -> [BreedImagesViewModel.DataObject] {
        breedImagesCollectionView.visibleCells
            .compactMap { [breedImagesCollectionView] cell in
                breedImagesCollectionView.indexPath(for: cell)
            }
            .compactMap { [collectionViewDataSource] cellIndex in
                collectionViewDataSource.itemIdentifier(for: cellIndex)
            }
    }

    private func subscribe() {
        breedImagesViewModel.visibleItems = { [unowned self] in
            self.visibleItems()
        }
        subscriptions.add([
            // Content
            breedImagesViewModel
                .$snapshot
                .executeOnMain(collectionViewDataSource.apply),
            breedImagesViewModel
                .isContentRefreshing
                .executeOnMain(refreshingControl.updateRefreshing),
            // No data label
            breedImagesViewModel
                .noDataLabelText
                .weakAssignOnMain(to: \.text, on: noDataLabel),
            breedImagesViewModel
                .isNoDataLabelHidden
                .weakAssignOnMain(to: \.isHidden, on: noDataLabel),
            refreshingControl
                .beginRefreshingPublisher
                .weakAssign(to: \.beginRefreshing, on: breedImagesViewModel)
        ])

        if breedImagesViewModel.showSearchBar {
            subscriptions.add([
                // Search
                searchResultViewController
                    .itemSelectedPublisher
                    .executeOnMain(breedImagesViewModel.searchResultsItemSelected),
                breedImagesViewModel
                    .searchResultsDismissingPublisher
                    .executeOnMain(searchController.dismiss),
                breedImagesViewModel
                    .searchResultsPublisher
                    .executeOnMain(searchResultViewController.replace),
                breedImagesViewModel
                    .$searchText
                    .weakAssign(to: \.text, on: searchController.searchBar),
                breedImagesViewModel
                    .$isSearchBarEnabled
                    .weakAssign(to: \.isUserInteractionEnabled, on: searchController.searchBar)
            ])
        }
    }

    private func makeUICollectionView() -> UICollectionView {
        // And create the UICollection View
        UICollectionView(frame: .zero,
                         collectionViewLayout: CollectionViewLayoutFactory().makeBreedsCollectionViewLayout()).then {
            // Register a cell
            $0.register(BreedImagesCollectionViewCell.self)
            $0.delegate = self
            if breedImagesViewModel.isPullToRefreshEnabled {
                $0.refreshControl = refreshingControl
            }
            $0.backgroundColor = .systemBackground
        }
    }

    private func makeCollectionViewDataSource(for collectionView: UICollectionView) -> DataSource {
        DataSource(collectionView: collectionView) { [unowned self] (collectionView, indexPath, data) -> UICollectionViewCell? in
            let imageCell: BreedImagesCollectionViewCell = collectionView
                .dequeueReusableCell(for: indexPath)
            self.configure(cell: imageCell, with: data)
            return imageCell
        }
    }

    private func configure(cell: BreedImagesCollectionViewCell, with imageUrl: BreedImagesViewModel.DataObject) {
        // Download an image asynchronously using an url from photo metadata
        // The amount of the following publishers in the memory will be equal to an amount of visible cells
        cell.imageDownloadingSubscription = breedImagesViewModel
            .imagePublisher(for: imageUrl,
                            activityAnimating: cell.activityIndicator)
            .weakAssign(to: \.image, on: cell.imageView)
        cell.favoriteIconSubscription = breedImagesViewModel
            .isFavoritePublisher(for: imageUrl)
            .map { !$0 }
            .weakAssign(to: \.isOn, on: cell.favoriteView)
    }
}

extension BreedImagesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let imageUrl = collectionViewDataSource
                .itemIdentifier(for: indexPath) else {
            return
        }
        breedImagesViewModel.imageSelected(with: imageUrl)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        breedImagesViewModel.shouldSelectItem
    }
}

extension BreedImagesViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        breedImagesViewModel.searchBarSearchButtonClicked(searchBar.text ?? "")
    }
}

extension BreedImagesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Apply the filtered results to the search results table.
        breedImagesViewModel.updateSearchResults(searchController.searchBar.text ?? "")
    }
}
