//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

extension UITableView {
    /// Type agnostic variant of the cell instantiating function
    func dequeueReusableCell<T: ReuseIdentifiable>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier,
                                             for: indexPath) as? T else {
            fatalError("Failed to init \(UITableViewCell.self) for indexPath: \(indexPath)")
        }
        return cell
    }
}
