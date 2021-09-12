//
// Copyright © 2021 Dmitry Rybakov. All rights reserved. 
    

import UIKit

extension UICollectionView {
    /// Shorten varian of a cell registering function
    func register<T: AnyObject & ReuseIdentifiable>(_ cellClass: T.Type) {
        register(cellClass, forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    /// Type agnostic variant of the cell instantiating function
    func dequeueReusableCell<T: ReuseIdentifiable>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Failed to init \(UICollectionViewCell.self) for indexPath: \(indexPath)")
        }
        return cell
    }
}
