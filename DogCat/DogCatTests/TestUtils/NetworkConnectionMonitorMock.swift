//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import Combine
@testable import DogCat

final class NetworkConnectionMonitorMock: NetworkConnectionMonitoring {
    @Published var connectionState = true

    func noConnectionWithDelay(oneShot: Bool) -> AnyPublisher<Void, Never> {
        // Since a delay is not important in this case do not use it to speed up unit testing
        Just(())
            .flatMap { [weak self] _ -> AnyPublisher<Bool, Never> in
                guard let self = self else {
                    return Empty<Bool, Never>()
                        .eraseToAnyPublisher()
                }
                return self.$connectionState
                    .eraseToAnyPublisher()
            }
            .filter { !$0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func connectionAvailable(oneShot: Bool) -> AnyPublisher<Void, Never> {
        $connectionState
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
