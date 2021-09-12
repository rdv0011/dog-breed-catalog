//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit
import Combine

class SearchResultsViewModel<T: Hashable> {
    // MARK: - Type Aliases
    typealias DataObject = T
    typealias DataSection = Int
    typealias DataSnapshot = NSDiffableDataSourceSnapshot<DataSection, DataObject>

    // MARK:- Public vars
    @Published var snapshot = DataSnapshot().with {
        // Setup one section only
        $0.appendSections([1])
    }

    private let sectionIndex = 1
    private var firstRun = true

    func replace(_ items: [T]) {
        replaceSnapshot(with: items, in: sectionIndex)
    }

    private func replaceSnapshot(with items: [DataObject], in section: DataSection) {
        let identifiers = snapshot.itemIdentifiers
        // Remove previously added items
        if identifiers.count > 0 {
            snapshot.deleteItems(identifiers)
        }
        // Add new items
        if snapshot.sectionIdentifiers.contains(section) {
            snapshot.appendItems(items, toSection: section)
        } else {
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }
    }
}
