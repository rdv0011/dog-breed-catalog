//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import UIKit
import Combine

extension UIRefreshControl {

    /// This publisher is supposed to be called from the main thread otherwise it might lead to an unpredictable behaviour
    var beginRefreshingPublisher: AnyPublisher<Void, Never> {
        beginRefreshingSubject.eraseToAnyPublisher()
    }

    /// Start refreshing control animation and move associated table view down for a control to be visible
    /// - NOTE: Does not send ```.valueChanged``` event
    func startAnimating() {
        guard !isRefreshing else { return }
        if let scrollView = superview as? UIScrollView {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.height), animated: false)
        }
        beginRefreshing()
    }

    /// Starts or stops animation process
    ///
    /// - Parameters:
    ///   - isOngoing: If true starts animation and stops otherwise
    func updateRefreshing(_ isOngoing: Bool) {
        if isOngoing {
            self.startAnimating()
        } else {
            self.endRefreshing()
        }
    }

    private static var beginRefreshingAssociatedKey = "beginRefreshingAssociatedKey"
    private typealias BeginRefreshingSubject = PassthroughSubject<Void, Never>

    /// Returns a publisher subject which is stored as an associated object
    private var beginRefreshingSubject: BeginRefreshingSubject {
        if let subject = objc_getAssociatedObject(
            self,
            &Self.beginRefreshingAssociatedKey) as? BeginRefreshingSubject {
            return subject
        } else {
            // A strong reference to an object until it is set as an associated with ```objc_set```
            var subject: BeginRefreshingSubject?

            if Thread.current.isMainThread {
                makeBeginRefreshingSubject(&subject)
            } else {
                DispatchQueue.main.sync {
                    makeBeginRefreshingSubject(&subject)
                }
            }

            guard let subject = subject else {
                fatalError("Failed to init \(UIRefreshControl.self) \(Self.beginRefreshingAssociatedKey)")
            }

            return subject
        }
    }

    /// Creates a publisher subject and set it as an associated object
    private func makeBeginRefreshingSubject(_ subject: inout BeginRefreshingSubject?) {
        // Init a publisher subject
        let beginRefreshingAssociatedObject = BeginRefreshingSubject()
        subject = beginRefreshingAssociatedObject

        objc_setAssociatedObject(self,
                                 &Self.beginRefreshingAssociatedKey,
                                 beginRefreshingAssociatedObject,
                                 // Use non atomic since get/set are used from the same main thread non concurently
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self,
                  action: #selector(handleValueChanged),
                  for: .valueChanged)
    }

    /// Notifies a publisher subscribers about an event from ```UIRefreshingControl```
    @objc
    private func handleValueChanged() {
        beginRefreshingSubject.send()
    }
}
