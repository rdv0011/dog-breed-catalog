//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

extension UIView {
    /// Controls is autoresizing feature is on or off
    /// Allows to write more cleaner code with shortened names
    public var isAutoLayout: Bool {
        get { !translatesAutoresizingMaskIntoConstraints }
        set { translatesAutoresizingMaskIntoConstraints = !newValue }
    }

    /// Establishes auto-layout constraints
    /// Implements the most common use case when a subview wants to cover the full area of the superview
    public func fillSuperview(withInsets insets: UIEdgeInsets = .zero) {
        guard let superview = superview else {
            assertionFailure("Failed to add constraints for a view not in a hierarchy")
            return
        }
        isAutoLayout = true
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }
}
