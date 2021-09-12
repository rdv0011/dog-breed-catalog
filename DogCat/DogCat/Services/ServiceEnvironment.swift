//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// Represents different backend environment types
/// Creates a network service configuration for a specified type
enum ServiceEnvironment {
    case dev
}

/// Represents a base URL of the backend service
enum DogServiceBaseUrl: String {
    case dev = "https://dog.ceo/api"

    func url() -> URL {
        guard let baseUrl = URL(string: self.rawValue) else {
            fatalError("Failed to build url")
        }
        return baseUrl
    }
}

extension ServiceEnvironment {
    /// - Returns: A network service configuration for a chosen environment configuration
    func makeDogServiceConfiguration() -> DogService.Configuration {
        switch self {
        case .dev:
            return makeDebugDogServiceConfiguration()
        }
    }

    /// - Returns: Network service configuration for a debug environment
    private func makeDebugDogServiceConfiguration() -> DogService.Configuration {
        DogService.Configuration(baseUrl: .dev,
                                 urlSession: URLSession.shared,
                                 jsonDecoder: JSONDecoder())
    }
}
