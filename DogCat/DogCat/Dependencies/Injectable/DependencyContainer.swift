//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import OrderedCollections

/// Allows to define dependencies in a convenient DSL style
///
/// The implementation uses a singleton pattern which is ok since it will not be extended/changed significantly
/// A conformance to a singleton pattern does not affect a possibility to mock dependencies for unit testing either.
/// Corresponding dependency creating blocks are not called right away but when necessary only where [Injectable](x-source-tag://Injectable) is used
///
/// ### Usage Example: ###
/// ```
/// DependencyContainer {
///     Dependency { Service() }
///     \\ ...
/// }
/// .build()
/// ```
/// - Tag: DependencyContainer
final class DependencyContainer {
    // MARK:- Singleton
    private(set) static var shared = DependencyContainer()
    // Make a default constructor inaccessible
    private init() {}

    private var dependencies = OrderedDictionary<String, Dependency>()

    // DSL support
    @resultBuilder enum DependencyBuilder {
        static func buildBlock(_ dependency: Dependency) -> Dependency {
            dependency
        }
        static func buildBlock(_ dependencies: Dependency...) -> [Dependency] {
            dependencies
        }
    }

    init(@DependencyBuilder _ dependency: () -> Dependency) {
        register(dependency())
    }

    init(@DependencyBuilder _ dependencies: () -> [Dependency]) {
        dependencies().forEach { dependency in
            register(dependency)
        }
    }

    func register(_ dependency: Dependency) {
        guard dependencies[dependency.name] == nil else {
            log.debug("\(dependency.name) has already been registered")
            return
        }
        dependencies[dependency.name] = dependency
    }

    func build() {
        dependencies.keys.forEach { key in
            dependencies[key]?.resolve()
        }
        Self.shared = self
    }

    func resolve<T>() -> T {
        guard let dependency = dependencies
                .first(where: { $0.value.value is T })?
                .value.value as? T else {
            fatalError("Failed to find \(T.self) in \(dependencies)")
        }
        return dependency
    }

    func remove<T>(_ dependency: T) {
        guard let key = dependencies
                .first(where: { $0.value.value is T })?
                .key else {
           return
        }
        dependencies[key] = nil
    }
}

extension DependencyContainer: Sequence {
    func makeIterator() -> AnyIterator<Any> {
        var iterator = dependencies.makeIterator()
        return AnyIterator { iterator.next()?.value.value }
    }
}
