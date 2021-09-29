//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine
import UIKit

class BreedsViewModel {
    // MARK: - Type Aliases
    typealias DataObject = String
    typealias DataSection = Int
    typealias DataSnapshot = NSDiffableDataSourceSnapshot<DataSection, DataObject>

    // MARK:- Public vars
    @Published var snapshot : DataSnapshot = {
        var snapshot = DataSnapshot()
        // Setup one section only
        snapshot.appendSections([BreedsViewModel.sectionIndex])
        return snapshot
    }()

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
    var isFavoritesButtonEnabled: AnyPublisher<Bool, Never> {
        availableContent
            .map { contentAvailability in contentAvailability?.available }
            .replaceNil(with: false)
            .eraseToAnyPublisher()
    }
    let title = Localized.breedNamesScreenTitle

    // Is used to inform a view model that refreshing has ben initiated externally by the user
    @Published var beginRefreshing: Void = ()
    @Published private var contentRefreshing: ViewModelContentRefreshingState = .finished(contentAvailable: nil)

    // MARK:- Constants
    private static let sectionIndex = 1

    // MARK: - Private vars
    private var availableContent: AnyPublisher<ViewModelContentAvailability?, Never> {
        $contentRefreshing
            .map { refreshing in refreshing.availableContent }
            .eraseToAnyPublisher()
    }

    private var subscriptions = [AnyCancellable]()
    private var breedNameToRandomImageUrls = [String: URL]()

    // MARK:- Dependencies
    @Injectable private var dogService: DogServicable
    @Injectable private var connectionMonitoring: NetworkConnectionMonitoring

    init() {
        subscribe()
    }

    func image(for breedName: String,
               activityAnimating: ActivityAnimating?) -> AnyPublisher<UIImage?, Never> {
        randomImageWithCaching(for: breedName)
            // On error set an empty image
            // It does not make sense to re-try because scrolling is continuous
            // In a second the user might appear at some other position far away from the current
            // Once it happens the image will be downloaded again for this particular position
            .replaceError(with: nil)
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

    private func randomImageWithCaching(for breedName: String) -> AnyPublisher<UIImage?, NetworkCommunicationError> {
        // Do a simple in-memory caching to show the same title image for each breed when scrolling
        Just(breedNameToRandomImageUrls[breedName])
            .flatMap { [dogService] imageUrl -> AnyPublisher<URL, NetworkCommunicationError> in
                guard let imageUrl = imageUrl else {
                    return dogService
                        .randomImageUrl(for: breedName)
                        .eraseToAnyPublisher()
                }
                return Just(imageUrl)
                    .setFailureType(to: NetworkCommunicationError.self)
                    .eraseToAnyPublisher()
            }
            .flatMap { [unowned self] imageUrl -> AnyPublisher<UIImage?, Never> in
                self.breedNameToRandomImageUrls[breedName] = imageUrl
                return self.dogService.image(from: imageUrl)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private functions
    private func subscribe() {
        allBreedsSubscription()
            .store(in: &subscriptions)
    }

    private func allBreedsSubscription() -> AnyCancellable {
        $beginRefreshing
            .handleEvents(receiveOutput: { [unowned self] _ in
                self.contentRefreshing = .ongoing
            })
            .map { [unowned self] _ in
                self.dogService
                    .allBreeds()
                    // Start no connection monitoring
                    .merge(with: self.noConnectionWithDelayPublisher())
            }
            .switchToLatest()
            .sink { [unowned self] completion in
                if case .failure = completion {
                    self.contentRefreshing = .finished(contentAvailable: .no(reason: Localized.generalNetworkingUnrecoverableError))
                }
            } receiveValue: { [unowned self] breeds in
                self.contentRefreshing = breeds.count > 0 ? .finished(contentAvailable: .yes): .finished(contentAvailable: .no(reason: Localized.generalNetworkingNoData))
                self.replaceSnapshot(with: breeds, in: Self.sectionIndex)
            }
    }

    private func noConnectionWithDelayPublisher<T>() -> AnyPublisher<T, NetworkCommunicationError> {
        connectionMonitoring
            .noConnectionWithDelay()
            .flatMap { [unowned self] _ -> AnyPublisher<T, NetworkCommunicationError> in
                // If refresh is ongoing and there is no network then inform the user
                if self.contentRefreshing.isOngoing {
                    self.contentRefreshing = .finished(contentAvailable: .no(reason: Localized.generalNetworkingNoNetwork))
                }
                // Do let the value to go to the handling block of a network request publisher
                return Empty<T, NetworkCommunicationError>()
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
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
}
