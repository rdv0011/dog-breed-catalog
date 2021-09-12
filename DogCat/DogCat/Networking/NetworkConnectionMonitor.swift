//
// Copyright © 2021 Dmitry Rybakov. All rights reserved. 
    

import Foundation
import Combine

/// Helper publishers to get the network connection status
protocol NetworkConnectionMonitoring {
    /// - Parameters:
    ///   - oneShot: if True behaves like a one-shot otherwise like a  non limited set of values publisher
    /// - Returns: Emits a value when the connection is lost
    /// - Note: Implementation buffers the current value therefore a current value will be emitted upon a subscription
    func noConnectionWithDelay(oneShot: Bool) -> AnyPublisher<Void, Never>
    /// - Parameters:
    ///   - oneShot: if True behaves like a one-shot otherwise like a  non limited set of values publisher
    /// - Returns: Emits a value when the connection is re-established
    /// - Note: Implementation buffers the current value therefore a current value will be emitted upon a subscription
    func connectionAvailable(oneShot: Bool) -> AnyPublisher<Void, Never>
}

extension NetworkConnectionMonitoring {
    func noConnectionWithDelay() -> AnyPublisher<Void, Never> {
        noConnectionWithDelay(oneShot: true)
    }
    func connectionAvailable() -> AnyPublisher<Void, Never> {
        connectionAvailable(oneShot: true)
    }
}

class NetworkConnectionMonitor {
    private lazy var reachability = try? Reachability()
    private lazy var reachabilitySubject = CurrentValueSubject<Bool, Never>(false)
    private var subscriptions = Set<AnyCancellable>()
    private let noConnectionDelaySeconds: TimeInterval = 5

    init(appLifeCycle: AnyPublisher<AppLifecycleEvent, Never>) {
        setupSubscriptions(appLifeCycle)
        startReachability()
    }

    private func setupSubscriptions(_ appLifeCycle: AnyPublisher<AppLifecycleEvent, Never>) {
        appLifeCycle
            .sink { [unowned self] lifeCycleEvent in
                switch lifeCycleEvent {
                case .applicationDidEnterBackground:
                    self.stopReachability()
                case .applicationWillEnterForeground:
                    self.startReachability()
                }
            }
            .store(in: &subscriptions)
    }

    private func startReachability() {
        guard let reachability = reachability else {
            fatalError("Failed to init \(Reachability.self)")
        }

        do {
            reachability.whenReachable = { [unowned self] _ in
                self.reachabilitySubject.send(true)
            }
            reachability.whenUnreachable = { [unowned self] _ in
                self.reachabilitySubject.send(false)
            }
            try reachability.startNotifier()
        } catch {
            fatalError("Failed to start \(Reachability.self)")
        }
    }

    private func stopReachability() {
        reachability?.stopNotifier()
    }
}

extension NetworkConnectionMonitor: NetworkConnectionMonitoring {
    func noConnectionWithDelay(oneShot: Bool) -> AnyPublisher<Void, Never> {
        if oneShot {
            return noConnectionWithDelayPublisher()
                // Transform a continuous publisher into a one-shot one
                // It will send .finished once the first value is sent
                .first()
                .eraseToAnyPublisher()
        } else {
            return noConnectionWithDelayPublisher()
        }
    }

    func connectionAvailable(oneShot: Bool) -> AnyPublisher<Void, Never> {
        if oneShot {
            return connectionAvailablePublisher()
                // Transform a continuous publisher into a one-shot one
                // It will send .finished once the first value is sent
                .first()
                .eraseToAnyPublisher()
        } else {
            return connectionAvailablePublisher()
        }
    }

    private func noConnectionWithDelayPublisher() -> AnyPublisher<Void, Never> {
        Just(())
            .delay(for: .seconds(noConnectionDelaySeconds), scheduler: DispatchQueue.main)
            .flatMap { [reachabilitySubject] in
                reachabilitySubject.eraseToAnyPublisher()
            }
            // Passthrough if the network is not available
            .filter { available in !available }
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func connectionAvailablePublisher() -> AnyPublisher<Void, Never> {
        Just(())
            .flatMap { [reachabilitySubject] in
                reachabilitySubject.eraseToAnyPublisher()
            }
            // Passthrough if the network is available
            .filter { available in available }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
