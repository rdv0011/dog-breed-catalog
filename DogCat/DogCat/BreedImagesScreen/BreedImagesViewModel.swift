//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine
import UIKit

class BreedImagesViewModel {
    // MARK: - Type Aliases
    typealias DataObject = URL
    typealias DataSection = Int
    typealias DataSnapshot = NSDiffableDataSourceSnapshot<DataSection, DataObject>

    // MARK: - Additional Structures
    enum Mode {
        case breeds(name: String)
        case favorites

        var noDataText: String {
            switch self {
            case .breeds:
                return Localized.generalNetworkingNoData
            case .favorites:
                return Localized.favoritesScreenNoResults
            }
        }

        var title: String {
            switch self {
            case .breeds(let name):
                return "\(name)"
            default:
                return Localized.favoritesScreenTitle
            }
        }

        var isFavoritesMode: Bool {
            switch self {
            case .favorites:
                return true
            default:
                return false
            }
        }
    }
    // MARK:- Constants
    private static let sectionIndex = 1

    // MARK:- Public vars
    @Published var snapshot : DataSnapshot = {
        var snapshot = DataSnapshot()
        // Setup one section only
        snapshot.appendSections([BreedImagesViewModel.sectionIndex])
        return snapshot
    }()

    // This property is called frequently, so use ```lazy``` to cash its value
    lazy var shouldSelectItem: Bool = {
        !mode.isFavoritesMode
    }()

    var showSearchBar: Bool {
        mode.isFavoritesMode
    }

    var title: String {
        mode.title.capitalizingFirstLetter()
    }

    @Published var searchText: String?

    var isContentRefreshing: AnyPublisher<Bool, Never> {
        $contentRefreshing
            .map { refreshing in refreshing.isOngoing }
            .eraseToAnyPublisher()
    }
    var noDataLabelText: AnyPublisher<String?, Never> {
        availableContent
            .map { contentAvailability in contentAvailability?.reason }
            .replaceNil(with: "")
            .eraseToAnyPublisher()
    }
    var isNoDataLabelHidden: AnyPublisher<Bool, Never> {
        availableContent
            .map { contentAvailability in contentAvailability?.available }
            .replaceNil(with: true)
            .eraseToAnyPublisher()
    }
    var isPullToRefreshEnabled: Bool {
        switch mode {
        case .breeds:
            return true
        default:
            return false
        }
    }
    @Published var isSearchBarEnabled: Bool = false
    // Is used to inform a view model that refreshing has ben initiated externally by the user
    @Published var beginRefreshing: Void = ()
    var visibleItems: (() -> [DataObject])?
    var searchResultsDismissingPublisher: AnyPublisher<Void, Never> {
        searchResultsDismissingSubject
            .eraseToAnyPublisher()
    }
    var searchResultsPublisher: AnyPublisher<[String], Never> {
        searchResultsSubject
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK:- Private vars
    private var subscriptions = Set<AnyCancellable>()
    private let mode: Mode
    @Published private var contentRefreshing: ViewModelContentRefreshingState = .finished(contentAvailable: nil)
    private var availableContent: AnyPublisher<ViewModelContentAvailability?, Never> {
        $contentRefreshing
            .map { refreshing in refreshing.availableContent }
            .eraseToAnyPublisher()
    }
    private let searchResultsDismissingSubject = PassthroughSubject<Void, Never>()
    private let searchResultsSubject = PassthroughSubject<[String], Never>()

    // MARK:- Dependencies
    @Injectable private var connectionMonitoring: NetworkConnectionMonitoring
    @Injectable private var dogService: DogServicable
    @Injectable private var favoritesStore: FavoritesStoring

    init(mode: Mode) {
        self.mode = mode

        subscribe()
    }

    deinit {
        log.verbose(.breedImages, "Deinit \(BreedImagesViewModel.self)")
    }

    // MARK: - Public functions
    func imagePublisher(for url: URL,
                        activityAnimating: ActivityAnimating? = nil) -> AnyPublisher<UIImage?, Never> {
        dogService
            .image(from: url)
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveSubscription: { _ in
                activityAnimating?.startAnimating()
            }, receiveOutput: { _ in
                activityAnimating?.stopAnimating()
            })
            // Remove previously set image
            .prepend(nil)
            .eraseToAnyPublisher()
    }

    func isFavoritePublisher(for url: URL) -> AnyPublisher<Bool, Never> {
        // Monitor a DB changes for a favorite status
        switch mode {
        case .breeds(let name):
            return favoritesStore.publisher(for: Breed(imageUrl: url, breedName: name))
        case .favorites:
            // All images on the favorites screen has a favorite icon on
            return Just(true).eraseToAnyPublisher()
        }
    }

    func imageSelected(with imageUrl: URL) {
        switch mode {
        case .breeds(let name):
            log.verbose(.breedImages, "Favorite toggled: breedName: \(name) url: \(imageUrl)")
            favoritesStore.toggle(for: Breed(imageUrl: imageUrl, breedName: name))
        default:()
            // Do nothing on the favorites screen
        }
    }

    func searchResultsItemSelected(_ searchText: String) {
        self.searchText = searchText
        searchResultsDismissingSubject.send()
    }

    func searchBarSearchButtonClicked(_ searchText: String) {
        self.searchText = searchText
        searchResultsDismissingSubject.send()
    }

    func updateSearchResults(_ searchText: String) {
        searchResultsSubject.send(searchResults(for: searchText))
    }

    private func findMatches(for searchString: String) -> NSComparisonPredicate {
        let breedNameExpression = NSExpression(format: "SELF")
        let searchStringExpression = NSExpression(forConstantValue: searchString)

        return NSComparisonPredicate(leftExpression: breedNameExpression,
                                     rightExpression: searchStringExpression,
                                     modifier: .direct,
                                     type: .contains,
                                     options: [.caseInsensitive, .diacriticInsensitive])
    }

    // MARK: - Private functions
    private func subscribe() {
        switch mode {
        case .breeds(let breedName):
            subscriptions.add([
                breedImageUrlsSubscription(for: breedName),
                reloadVisibleItemsSubscription()
            ])
        case .favorites:
            searchTexSubscription()
                .store(in: &subscriptions)
        }
    }

    private func breedImageUrlsSubscription(for breedName: String) -> AnyCancellable {
        $beginRefreshing
            .handleEvents(receiveOutput: { [unowned self] _ in
                self.contentRefreshing = .ongoing
                log.debug(.breedImages, "Content refreshing started")
            })
            .map { [unowned self] _ in
                self.dogService.allImageUrls(for: breedName)
                    // Start no connection monitoring
                    .merge(with: noConnectionWithDelayPublisher())
            }
            // Cancel previous requests since pull to refresh may emit more values before imageUrl request finished
            .switchToLatest()
            .catch { [unowned self] error -> AnyPublisher<[URL], Never> in
                self.contentRefreshing = .finished(contentAvailable: .no(reason: Localized.generalNetworkingUnrecoverableError))
                log.debug(.breedImages, "Unrecoverable error. Content refreshing finished: \(self.contentRefreshing)")
                return Empty<[URL], Never>()
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [unowned self] completion in
                log.debug(.breedImages, "Finished \(String(describing: self.breedImageUrlsSubscription))")
            }, receiveValue: { [unowned self] imageUrls in
                self.contentRefreshing = imageUrls.count > 0 ? .finished(contentAvailable: .yes): .finished(contentAvailable: .no(reason: self.mode.noDataText))
                self.replaceSnapshot(with: imageUrls, in: Self.sectionIndex)
                log.debug(.breedImages, "Content refreshing finished: \(self.contentRefreshing)")
            })
    }

    private func noConnectionWithDelayPublisher<T>() -> AnyPublisher<T, NetworkCommunicationError> {
        connectionMonitoring
            .noConnectionWithDelay()
            .flatMap { [unowned self] _ -> AnyPublisher<T, NetworkCommunicationError> in
                // If refresh is ongoing and there is no network then inform the user
                if self.contentRefreshing.isOngoing {
                    self.contentRefreshing = .finished(contentAvailable: .no(reason: Localized.generalNetworkingNoNetwork))
                    log.verbose(.breedImages, "No connection available. Content refreshing finished: \(self.contentRefreshing)")
                }
                // Do let the value to go to the handling block of a network request publisher
                return Empty<T, NetworkCommunicationError>()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func reloadVisibleItemsSubscription() -> AnyCancellable {
        connectionMonitoring
            .connectionAvailable(oneShot: false)
            .compactMap { [unowned self] _ in
                self.visibleItems?()
            }
            .sink { [unowned self] imageUrls in
                guard imageUrls.count > 0 else {
                    return
                }
                log.verbose(.breedImages, "No connection available. Content refreshing finished: \(self.contentRefreshing)")
                // The connection may disappear when scrolling items, so some of them may  end up being empty
                // Try to reload visible items once the connection is available
                self.snapshot.reloadItems(imageUrls)
            }
    }

    private func searchTexSubscription() -> AnyCancellable {
        // Store a subscription to a dedicated var to avoid leaks due to frequent changes
        $searchText
            .removeDuplicates()
            .replaceNil(with: "")
            .handleEvents(receiveOutput: { [unowned self] _ in
                self.contentRefreshing = .ongoing
                log.debug(.breedImages, "Content refreshing started")
            })
            .map { [unowned self] breedName in
                self.favoriteUrlsFiltered(by: breedName)
            }
            .sink { [unowned self] imageUrls in
                self.contentRefreshing = imageUrls.count > 0 ? .finished(contentAvailable: .yes): .finished(contentAvailable: .no(reason: self.mode.noDataText))
                log.debug(.breedImages, "Content refreshing finished: \(self.contentRefreshing)")
                self.replaceSnapshot(with: imageUrls, in: Self.sectionIndex)
            }
    }

    /// Modify a datasource snapshot
    private func replaceSnapshot(with items: [DataObject], in section: DataSection) {
        let identifiers = snapshot.itemIdentifiers
        // Remove previously added items
        if identifiers.count > 0 {
            snapshot.deleteItems(identifiers)
        }
        // Add new items
        if snapshot.sectionIdentifiers.contains(section) {
            snapshot.appendItems(items, toSection: section)
        } else {
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }
    }

    private func favoriteUrlsFiltered(by breedName: String) -> [DataObject] {
        let allBreeds =
            favoritesStore
                .all()

        isSearchBarEnabled = allBreeds.count > 0

        return allBreeds
            .filter {
                guard !breedName.isEmpty else {
                    // If a string is empty or nil skip filtering
                    return true
                }
                return $0.breedName.range(of: breedName, options: .caseInsensitive) != nil
            }
            .map {
                $0.imageUrl
            }
    }

    private func searchResults(for searchString: String) -> [String] {
        // Update the filtered array based on the search text.
        let searchResults = Array(Set(favoritesStore
                                        .all()
                                        .map { breed in
                                            breed.breedName.capitalizingFirstLetter()
                                        }))
            .sorted()

        guard !searchString.isEmpty else {
            return searchResults
        }

        // Build all the "AND" expressions for each value in searchString.
        let andMatchPredicates: [NSPredicate] = searchString
            .stripping()
            .map { searchString in
                findMatches(for: searchString)
            }
        // Match up the fields of the Product object.
        let finalCompoundPredicate =
            NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)

        return searchResults
            .filter {
                finalCompoundPredicate.evaluate(with: $0)
            }
    }
}
