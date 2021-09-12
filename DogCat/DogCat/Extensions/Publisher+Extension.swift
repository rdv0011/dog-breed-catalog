//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine

extension Publisher where Failure == Never {
    // MARK:- Avoiding Retain Cycles
    func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
    func weakAssign<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output?>,
        on object: T
    ) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
    func weakAssignOnMain<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output>,
        on object: T
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
    }
    func weakAssignOnMain<T: AnyObject>(
        to keyPath: ReferenceWritableKeyPath<T, Output?>,
        on object: T
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { [weak object] value in
                object?[keyPath: keyPath] = value
            }
    }

    // MARK: - Syntax sugar

    /// Allows to write one line for an action being executed upon receiving a value from the publisher
    /// - NOTE: This function must not be used to execute a function on ```self``` otherwise a retain cycle will be created
    /// It is supposed to be used to execute a function using the reference which a part of vars section of the class.
    /// Example:
    /// ```swift
    /// import UIKit
    /// import Combine
    /// class TestViewController {
    ///     let view = UIView()
    ///     var subscriptions = Set<AnyCancellable>()
    ///     var testPublisher: AnyPublisher<View, Never> {
    ///         Just().eraseToAnyPublisher()
    ///     }
    ///     func layoutSubviews() {
    ///         Just()
    ///             .executeOnMain(view.layoutSubviews())
    ///     }
    /// }
    ///```
    func executeOnMain(_ receiveValue: @escaping (Self.Output) -> Void) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
    }
}
