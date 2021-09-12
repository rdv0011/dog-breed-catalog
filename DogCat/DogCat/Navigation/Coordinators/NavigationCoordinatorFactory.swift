//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Incapsulates dependencies to create different types of coordinators
///
/// Helps to decouple coordinator specific dependencies from ```SceneDelegate```
final class NavigationCoordinatorFactory {

    lazy var connectionMonitoring: NetworkConnectionMonitoring = {
        NetworkConnectionMonitor(appLifeCycle: appDelegate.appLifecycle)
    }()
    lazy var breedsViewModelFactory: BreedsViewModelFactoryProtocol = {
        // Later some dependencies might be added here
        BreedsViewModelFactory(dogServiceConfiguration: ServiceEnvironment.dev.makeDogServiceConfiguration(),
                               connectionMonitoring: connectionMonitoring)
    }()

    private lazy var router: SceneDelegateRouter = {
        guard let window = window else {
            fatalError("Window is nil")
        }
        return SceneDelegateRouter(window: window)
    }()
    private weak var window: UIWindow?
    private let appDelegate: AppDelegate

    init(window: UIWindow, appDelegate: AppDelegate) {
        self.window = window
        self.appDelegate = appDelegate
    }

    func makeBreedsViewCoordinator() -> BreedsViewCoordinator {
        BreedsViewCoordinator(router: router,
                              viewModelFactory: breedsViewModelFactory)
    }
}
