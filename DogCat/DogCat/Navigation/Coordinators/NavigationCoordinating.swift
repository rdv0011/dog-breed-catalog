//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Navigate between view controllers
///
/// Coordinator is responsible for view controller instantiation but responsible for actual navigation stack manipulations
/// push/pop is implemented in the [NavigationRouting](x-source-tag://NavigationRouting)
/// Each coordinator is responsible for the whole feature section with multiple screens
/// - Tag: NavigationCoordinating
protocol NavigationCoordinating: AnyObject {
    var children: [NavigationCoordinating] { get set }
    var router: NavigationRouting { get }

    func present(animated: Bool, onDismissed: NavigationRouting.OnDismissedHandler?)
    func dismiss(animated: Bool)
    func present(child: NavigationCoordinating, animated: Bool, onDismissed: NavigationRouting.OnDismissedHandler?)
}

extension NavigationCoordinating {
    func dismiss(animated: Bool) {
        router.dismiss(animated: animated)
    }

    func present(animated: Bool) {
        present(animated: animated, onDismissed: nil)
    }

    func present(child: NavigationCoordinating, animated: Bool, onDismissed: NavigationRouting.OnDismissedHandler?) {
        children.append(child)
        child.present(animated: animated) { [weak self, weak child] in
            self?.children.removeAll { item in
                item === child
            }
            onDismissed?()
        }
    }
}
