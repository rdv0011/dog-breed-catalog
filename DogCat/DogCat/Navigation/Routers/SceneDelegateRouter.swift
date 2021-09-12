//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import UIKit

/// Main router to present a window with a root view controller
/// - Tag: SceneDelegateRouter
final class SceneDelegateRouter: NavigationRouting {
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
    }

    func present(_ viewController: UIViewController, animated: Bool, onDismissed: OnDismissedHandler?) {
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }

    func dismiss(animated: Bool) {
        fatalError("Not implemented")
    }
}
