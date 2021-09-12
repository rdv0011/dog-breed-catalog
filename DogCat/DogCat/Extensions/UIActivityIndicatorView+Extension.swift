//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

/// Decouple start/stop animating interface from the UIKit component to be UIKit free in some parts like view models
protocol ActivityAnimating {
    func startAnimating()
    func stopAnimating()
}

extension UIActivityIndicatorView {
    /// Helps to start/stop animating using publisher's ```assign```
    var isAnimationActive: Bool {
        get {
            isAnimating
        }
        set {
            newValue ?
                startAnimating(): stopAnimating()
        }
    }
}

extension UIActivityIndicatorView: ActivityAnimating {}
