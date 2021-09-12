//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation

/// The list of breeds with sub-breeds
/// - Tag: BreedNames
struct BreedNames: Decodable {
    let breeds: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case breeds = "message"
    }
}

/// The list of breed images
/// - Tag: BreedImageUrls
struct BreedImageUrls: Decodable {
    let imageUrls: [URL]

    enum CodingKeys: String, CodingKey {
        case imageUrls = "message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try to decode urls from strings
        self.imageUrls = try container
            .decode([String].self, forKey: .imageUrls)
            .map { imageUrlString in
                guard let imageUrl = URL(string: imageUrlString) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.imageUrls], debugDescription: "Failed to ini URL from: \(imageUrlString)"))
                }
                return imageUrl
            }
    }
}

/// A random breed image
/// - Tag: BreedRandomImageUrl
struct BreedRandomImageUrl: Decodable {
    let imageUrl: URL

    enum CodingKeys: String, CodingKey {
        case imageUrl = "message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try to decode a url from a string
        let imageUrlString = try container
                .decode(String.self, forKey: .imageUrl)
        guard let imageUrl = URL(string: imageUrlString) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.imageUrl], debugDescription: "Failed to ini URL from: \(imageUrlString)"))
        }
        self.imageUrl = imageUrl
    }
}

/// Combines an image of a specific dog and its breed name
/// - Tag: Breed
struct Breed: Identifiable, Codable {
    var id: String {
        imageUrl.absoluteString
    }
    let imageUrl: URL
    let breedName: String
}

extension Breed: Equatable {
}
extension Breed: Hashable {
}
