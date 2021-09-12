//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit
import Combine

final class SearchResultsTableViewController<T: TableViewCellConfigurable>: UIViewController, UITableViewDelegate {

    typealias DataSource = UITableViewDiffableDataSource<SearchResultsViewModel<T.T>.DataSection, T.T>

    var itemSelectedPublisher: AnyPublisher<T.T, Never> {
        itemSelectedSubject
            .eraseToAnyPublisher()
    }

    private lazy var tableView = UITableView().then {
        $0.delegate = self
        $0.tableFooterView = UIView()
        $0.backgroundColor = .clear
        $0.register(T.C.self,
                    forCellReuseIdentifier: T.C.reuseIdentifier)
    }
    private var itemSelectedSubject = PassthroughSubject<T.T, Never>()
    private lazy var dataSource: DataSource = {
        makeDataSource(for: tableView)
    }()
    private lazy var viewModel = SearchResultsViewModel<T.T>()
    private var subscriptions = Set<AnyCancellable>()
    private let cellConfigurator: T

    init(cellConfigurator: T) {
        self.cellConfigurator = cellConfigurator

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureLayout()
        subscribe()
    }

    deinit {
        log.verbose(.breedImages, "Deinit \(SearchResultsTableViewController.self)")
    }

    // MARK:- Public functions
    func replace(_ items: [T.T]) {
        viewModel.replace(items)
    }

    private func configureViews() {
        view.addSubview(tableView)
        view.backgroundColor = .clear
    }

    private func configureLayout() {
        tableView.fillSuperview()
    }

    private func isInHierarchy(_ view: UIView) -> Bool {
        view.superview?.superview != nil
    }

    private func subscribe() {
        subscriptions.add([
            viewModel
                .$snapshot
                .compactMap { [unowned self] snapshot in
                    // Defer reloading a tableview until it is in the view hierarchy
                    self.isInHierarchy(tableView) ? snapshot: nil
                }
                .executeOnMain(dataSource.apply)
        ])
    }

    private func makeDataSource(for tableView: UITableView) -> DataSource {
        DataSource(tableView: tableView) { [cellConfigurator] (tableView, indexPath, data) -> UITableViewCell? in
            let cell: T.C = tableView.dequeueReusableCell(for: indexPath)
            cellConfigurator.configure(cell, with: data)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let data = dataSource
                .itemIdentifier(for: indexPath) else {
            return
        }
        itemSelectedSubject.send(data)
    }
}
