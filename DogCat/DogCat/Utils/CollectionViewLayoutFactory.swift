//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

struct CollectionViewLayoutFactory {
    // MARK: - Layout constants
    private let itemSpacing = CGFloat(8) // 8pt grid
    private let itemsInOneLine = CGFloat(2)

    func makeBreedsCollectionViewLayout() -> UICollectionViewFlowLayout {
        UICollectionViewFlowLayout().then {
            $0.sectionInset = UIEdgeInsets(top: itemSpacing,
                                           left: itemSpacing,
                                           bottom: itemSpacing,
                                           right: itemSpacing)
            let width = UIScreen.main.bounds.size.width - itemSpacing * CGFloat(itemsInOneLine - 1) - 2 * itemSpacing
            $0.itemSize = CGSize(width: floor(width / itemsInOneLine),
                                 height: width / itemsInOneLine)
            $0.minimumInteritemSpacing = itemSpacing
            $0.minimumLineSpacing = itemSpacing
        }
    }
}
