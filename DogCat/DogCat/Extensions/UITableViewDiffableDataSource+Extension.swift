//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

extension UITableViewDiffableDataSource {

    /// Is used in conjunction with ```execute``` or ```executeOnMain``` in a publisher values handling chain
    func apply(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        apply(snapshot, animatingDifferences: true, completion: nil)
    }
}
