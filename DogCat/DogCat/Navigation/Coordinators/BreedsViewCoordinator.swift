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
        BreedsViewController(viewModel: BreedsViewModel()).then {
            $0.delegate = self
        }
    }()
    private lazy var breedsViewController = UINavigationController(rootViewController: breedsViewControllerUnwrapped)
    private lazy var childRouter = NavigationRouter(navigationController: breedsViewController)

    init(router: NavigationRouting) {
        self.router = router
    }

    func present(animated: Bool, onDismissed: (() -> Void)?) {
        router.present(breedsViewController,
                       animated: animated,
                       onDismissed: onDismissed)
    }
}

extension BreedsViewCoordinator: BreedsViewControllerDelegate {
    func breedSelected(breedName: String) {
        let breedImagesViewController = BreedImagesViewController(viewModel: BreedImagesViewModel(mode: .breeds(name: breedName)))
        childRouter.present(breedImagesViewController, animated: true)
    }

    func favoritesPressed() {
        let breedImagesViewController = BreedImagesViewController(viewModel: BreedImagesViewModel(mode: .favorites))
        childRouter.present(breedImagesViewController, animated: true)
    }
}
