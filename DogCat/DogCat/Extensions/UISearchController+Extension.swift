//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit
import Combine

extension UISearchController {
    var searchBarTextPublisher: AnyPublisher<String?, Never> {
        NotificationCenter.default.publisher(for: UISearchTextField.textDidChangeNotification,
                                             object: searchBar.searchTextField)
            .compactMap {
                ($0.object as? UISearchTextField)?.text
            }
            .eraseToAnyPublisher()
    }

    func dismiss() {
        dismiss(animated: true)
    }
}
