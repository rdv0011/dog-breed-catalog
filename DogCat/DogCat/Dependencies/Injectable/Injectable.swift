//
// Copyright © 2021 Dmitry Rybakov. All rights reserved. 

import Foundation

/// Allows to resolve a dependency for a specific type which is incrusted with this wrapper
///
/// ### Usage Example: ###
/// ```
/// @Injectable var service: Serviceable
/// service.doRequest()
/// ```
/// - Tag: Injectable
@propertyWrapper
struct Injectable<T> {
    private var dependency: T?

    var wrappedValue: T {
        mutating get {
            guard let dependency = self.dependency else {
                let dependency: T = DependencyContainer.shared.resolve()
                self.dependency = dependency
                return dependency
            }
            return dependency
        }

        set {
            dependency = newValue
        }
    }
}
