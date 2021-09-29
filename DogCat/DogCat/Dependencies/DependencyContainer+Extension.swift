//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Convenient methods to build dependencies
/// - Tag: DependencyContainer
extension DependencyContainer {
    /// Build dependencies
    ///
    /// Deallocates previous dependencies, therefore might be called several times
    /// - Parameters:
    ///   - environment: Defines an environment according to which the dependencies will be created
    static func build(for environment: ServiceEnvironment) {
        // Remove previous dependencies
        Self.remove()
        // Create new dependencies
        DependencyContainer {
            Dependency { environment.makeDogServiceConfiguration() }
            Dependency { FavoriteStore() }
            Dependency { NetworkConnectionMonitor(appLifeCycle: AppDelegate.shared.appLifecycle) }
            Dependency { DogService() }
            Dependency { ImageCache() }
        }
        .build()
    }

    /// Removes all dependencies
    static func remove() {
        DependencyContainer.shared.forEach { dependency in
            DependencyContainer.shared.remove(dependency)
        }
    }
}
