//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine
import UIKit

/// Manages networking JSON requests
/// - Tag: DogServicable
protocol DogServicable {
    /// - Returns: breeds names from a dog service
    func allBreeds() -> AnyPublisher<[String], NetworkCommunicationError>
    /// Gets all image urls  for provided breed name
    /// - Parameters:
    ///   - breedName: Dog breed name
    /// - Returns: Image urls otherwise error
    func allImageUrls(for breedName: String) -> AnyPublisher<[URL], NetworkCommunicationError>
    /// Downloads image by provided url
    /// - Parameters:
    ///   - url: url to operate with
    /// - Returns: Image otherwise nil
    func image(from url: URL) -> AnyPublisher<UIImage?, Never>
    /// Get random image url for provided breed name
    /// - Parameters:
    ///   - breedName: a dog breed name
    /// - Returns: Url otherwise error
    func randomImageUrl(for breedName: String) -> AnyPublisher<URL, NetworkCommunicationError>
}
