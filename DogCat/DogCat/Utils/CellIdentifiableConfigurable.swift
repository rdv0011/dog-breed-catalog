//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

protocol TableViewCellConfigurable {
    associatedtype C: UITableViewCell
    associatedtype T: Hashable
    func configure(_ cell: C, with data: T)
}

/// Provides an identifier for a reusable cell such as ```UITableViewCell``` and ```UICollectionViewCell```
protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}
