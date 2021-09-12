//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Combine

extension Set where Element: Cancellable {
    /// Allows to append subscription objects to a set
    public mutating func add(_ subscriptions: [Element]) {
        for item in subscriptions {
            self.insert(item)
        }
    }
}
