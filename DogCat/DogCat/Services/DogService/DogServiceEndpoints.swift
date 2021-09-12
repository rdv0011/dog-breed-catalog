//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// Represents types of the dog service endpoints
enum DogServiceEndpoints {
    /// Get all breeds
    case allBreeds
    /// Get all image URLs for a specific breed
    /// - Parameters:
    ///   - breedName: breed name
    case allImageUrls(_ breedName: String)
    /// Get a random image URL for a specific breed
    /// - Parameters:
    ///   - breedName: breed name
    case randomImageUrl(_ breedName: String)
}

extension DogServiceEndpoints: ServiceEndpointProviding {
    /// Returns a relative path to the backend's endpoint
    func path() -> String {
        switch self {
        case .allBreeds:
            return "breeds/list/all"
        case .allImageUrls(let breedName):
            return "breed/\(breedName)/images"
        case .randomImageUrl(let breedName):
            return "breed/\(breedName)/images/random"
        }
    }
}
