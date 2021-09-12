//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import UIKit

/// Navigates between screens related to breeds feature
/// - Tag: BreedsViewCoordinator
final class BreedsViewCoordinator: NavigationCoordinating {
    var children = [NavigationCoordinating]()

    var router: NavigationRouting
    private lazy var breedsViewControllerUnwrapped = {
        BreedsViewController(viewModel: self.viewModelFactory.makeBreedsViewModel()).then {
            $0.delegate = self
        }
    }()
    private lazy var breedsViewController = UINavigationController(rootViewController: breedsViewControllerUnwrapped)
    private lazy var childRouter = NavigationRouter(navigationController: breedsViewController)
    private let viewModelFactory: BreedsViewModelFactoryProtocol

    init(router: NavigationRouting,
         viewModelFactory: BreedsViewModelFactoryProtocol) {
        self.router = router
        self.viewModelFactory = viewModelFactory
    }

    func present(animated: Bool, onDismissed: (() -> Void)?) {
        router.present(breedsViewController,
                       animated: animated,
                       onDismissed: onDismissed)
    }
}

extension BreedsViewCoordinator: BreedsViewControllerDelegate {
    func breedSelected(breedName: String) {
        let viewModel = viewModelFactory.makeBreedImagesViewModel(mode: .breeds(name: breedName))
        let breedImagesViewController = BreedImagesViewController(viewModel: viewModel)
        childRouter.present(breedImagesViewController, animated: true)
    }

    func favoritesPressed() {
        let viewModel = viewModelFactory.makeBreedImagesViewModel(mode: .favorites)
        let breedImagesViewController = BreedImagesViewController(viewModel: viewModel)
        childRouter.present(breedImagesViewController, animated: true)
    }
}
