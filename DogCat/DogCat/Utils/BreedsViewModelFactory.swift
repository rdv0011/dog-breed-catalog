//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine

/// Create different types of view models for breeds screens
/// An implementation also incapsulates dependencies which makes a caller side is more simple
/// - Tag: BreedsViewModelFactoryProtocol
protocol BreedsViewModelFactoryProtocol {
    func makeBreedsViewModel() -> BreedsViewModel
    func makeBreedImagesViewModel(mode: BreedImagesViewModel.Mode) -> BreedImagesViewModel
}

class BreedsViewModelFactory {
    private let dogServiceConfiguration: DogService.Configuration
    private lazy var favoritesStore: FavoritesStoring = FavoriteStore()
    private let connectionMonitoring: NetworkConnectionMonitoring

    private lazy var dogService: DogService = {
        DogService(configuration: dogServiceConfiguration,
                   connectionMonitoring: connectionMonitoring)
    }()

    init(dogServiceConfiguration: DogService.Configuration,
         connectionMonitoring: NetworkConnectionMonitoring) {
        self.dogServiceConfiguration = dogServiceConfiguration
        self.connectionMonitoring = connectionMonitoring
    }
}

extension BreedsViewModelFactory: BreedsViewModelFactoryProtocol {
    func makeBreedsViewModel() -> BreedsViewModel {
        BreedsViewModel(dogService: dogService,
                        connectionMonitoring: connectionMonitoring)
    }

    func makeBreedImagesViewModel(mode: BreedImagesViewModel.Mode) -> BreedImagesViewModel {
        BreedImagesViewModel(dogService: dogService,
                             mode: mode,
                             favoritesStore: favoritesStore,
                             connectionMonitoring: connectionMonitoring)
    }
}
