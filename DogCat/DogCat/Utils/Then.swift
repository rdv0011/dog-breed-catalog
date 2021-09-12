//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import UIKit

/// - Tag: Then
protocol Then {}

extension Then where Self: Any {
    /// Copies the value type and updates the copy.
    @inlinable
    func with(_ update: (inout Self) throws -> Void) rethrows -> Self {
        var copyOfSelf = self
        try update(&copyOfSelf)
        return copyOfSelf
    }
}
/// Helps to set the properties of a created object at definition point
extension Then where Self: AnyObject {
    /// A shorten $0 notation to refer the object properties to shorten the code
    @inlinable
    func then(_ update: (Self) throws -> Void) rethrows -> Self {
        try update(self)
        return self
    }
}

extension UIViewController: Then {}
extension UIView: Then {}
extension UICollectionViewLayout: Then {}
extension NSDiffableDataSourceSnapshot: Then {}
extension CALayer: Then {}
