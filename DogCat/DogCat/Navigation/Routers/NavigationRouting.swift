//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import UIKit

/// Incapsulated actual navigation to decouple push/pop from [NavigationCoordinating](x-source-tag://NavigationCoordinating)
///
///  Usually it is needed to create a limited number of routers only.
///  Example:
///  - Main router for present the root view controller
///  - Router to navigate horizontally(push/pop)
///  - Router to navigate vertically(present modally)
/// - Tag: NavigationRouting
protocol NavigationRouting: AnyObject {
    typealias OnDismissedHandler = (() -> Void)

    func present(_ viewController: UIViewController,
                 animated: Bool,
                 onDismissed: OnDismissedHandler?)
    func dismiss(animated: Bool)
}

extension NavigationRouting {
    func present(_ viewController: UIViewController,
                 animated: Bool) {
        present(viewController,
                animated: animated,
                onDismissed: nil)
    }
}
