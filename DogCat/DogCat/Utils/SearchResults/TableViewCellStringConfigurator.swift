//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit

struct TableViewCellStringConfigurator: TableViewCellConfigurable {
    typealias C = UITableViewCell
    typealias T = String

    func configure(_ cell: C, with data: T) {
        cell.textLabel?.text = data
    }
}
