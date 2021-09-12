//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Concrete implementation of ```NavigationRouting```
/// Is used to navigate horizontally
class NavigationRouter: NSObject {
    private let navigationController: UINavigationController
    private let routerRootViewController: UIViewController?
    private var onDismissedByViewController = [UIViewController: OnDismissedHandler]()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.routerRootViewController = navigationController.viewControllers.first

        super.init()

        navigationController.delegate = self
    }
}

// MARK:- NavigationRouting conforming
extension NavigationRouter: NavigationRouting {
    func present(_ viewController: UIViewController, animated: Bool, onDismissed: OnDismissedHandler?) {
        onDismissedByViewController[viewController] = onDismissed
        navigationController.pushViewController(viewController,
                                     animated: animated)
    }

    func dismiss(animated: Bool) {
        guard let routerRootViewController = routerRootViewController else {
            navigationController.popToRootViewController(animated: animated)
            return
        }
        performOnDismissed(for: routerRootViewController)
        // Perform a navigation back to the parent view controller
        navigationController.popToViewController(routerRootViewController,
                                                 animated: animated)
    }

    // Should allow to be executed multiple times for the same view controller
    private func performOnDismissed(for viewController: UIViewController) {
        // Perform onDismissed block if it is set for this view controller
        onDismissedByViewController[viewController]?()
        // Remove onDismissed handler from the map
        onDismissedByViewController[viewController] = nil
    }
}

extension NavigationRouter: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Get a view controller we navigate from
        // Check if it is not in the navigation stack anymore
        // If it moves forward in the navigation stack then a previous view controller is still alive and no need to perform ```onDismissed```
        guard let dismissedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
              !navigationController.viewControllers.contains(dismissedViewController) else {
            return
        }
        performOnDismissed(for: dismissedViewController)
    }
}
