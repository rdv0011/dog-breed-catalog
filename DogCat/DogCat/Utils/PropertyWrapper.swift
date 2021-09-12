//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Property to switch on auto layout at the variable declaration
/// - Tag: UsesAutoLayout
@propertyWrapper
public struct UsesAutoLayout<T: UIView> {
    public var wrappedValue: T {
        didSet {
            wrappedValue.isAutoLayout = true
        }
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        wrappedValue.isAutoLayout = true
    }
}
