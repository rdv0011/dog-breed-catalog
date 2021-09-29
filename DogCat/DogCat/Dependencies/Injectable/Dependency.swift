//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// Associates dependency name with  a dependency
/// Dependency is supposed to be created lazily after ```init```
struct Dependency {
    private(set) var name: String
    private(set) var value: Any = ()

    private let resolveBlock: () -> Any

    init<T>(_ block: @escaping () -> T) {
        resolveBlock = block
        name = String(describing: T.self)
    }

    mutating func resolve() {
        value = resolveBlock()
    }
}
