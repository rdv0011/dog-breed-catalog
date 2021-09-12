//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import Combine

/// Is used to save and fetch from a persistent storage ```Breed``` objects
protocol FavoritesStoring {
    func toggle(for breed: Breed)
    func publisher(for breed: Breed) -> AnyPublisher<Bool, Never>
    func all() -> [Breed]
}

/// Sample implementation of ```Favorites``` persistent storage mechanizm
///
/// This implementation is based on the ```UserDefaults```
/// ```Breed``` type supports serialization to JSON string which is saved in the store
/// - Warning: To simplify implementation when changes is made to the store all objects are populated back to the publisher subscribers
/// Which may lead to extra work done in the UI
final class FavoriteStore: FavoritesStoring {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        if defaults.favorites == nil {
            log.debug(.favoritesStore, "Init empty storage for \(FavoriteStore.self)")
            defaults.setValue([:], forKey: UserDefaults.favoritesKey)
        }
    }

    /// - Returns: True if a provided objects exists in the store and False otherwise
    private func isFavorite(for breed: Breed) -> Bool {
        defaults.favorites?[breed.id] != nil
    }

    /// Adds the provided objects to the store if it does not exists and removes it otherwise
    func toggle(for breed: Breed) {
        var favorites = defaults.favorites
        let encodedBreedData: Data?
        if !isFavorite(for: breed) {
            encodedBreedData = try? encoder.encode(breed)
            log.verbose(.favoritesStore, "Add favorite to store: \(breed.id)")
        } else {
            encodedBreedData = nil
            log.verbose(.favoritesStore, "Remove favorite from store: \(breed.id)")
        }
        favorites?[breed.id] = encodedBreedData
        defaults.favorites = favorites
    }

    /// Notifies the subscribers when of the objects is added or removed from the store
    func publisher(for breed: Breed) -> AnyPublisher<Bool, Never> {
        defaults
            .publisher(for: \.favorites)
            .map { favorites in
                favorites?[breed.id] != nil
            }
            .handleEvents(receiveOutput: { isOn in
                log.verbose(.favoritesStore, "\(breed.id) favorite: \(isOn)")
            })
            .eraseToAnyPublisher()
    }

    /// - Returns: All objects from the store
    func all() -> [Breed] {
        let favorites = defaults.favorites?
            .compactMap { (key, encodedBreedData) -> Breed? in
                guard let breed =
                        try? decoder.decode(Breed.self, from: encodedBreedData) else {
                    log.error(.favoritesStore, "Failed to decode: key \(key) data \(encodedBreedData)")
                    return nil
                }
                return breed
            } ?? []
        return favorites
    }

    func removeAll() {
        defaults.setValue([:], forKey: UserDefaults.favoritesKey)
    }
}

extension UserDefaults {
    static let favoritesKey = "favoritesKey"
    @objc fileprivate dynamic var favorites: [String: Data]? {
        get {
            self.dictionary(forKey: UserDefaults.favoritesKey) as? [String: Data]
        }
        set {
            self.setValue(newValue, forKey: UserDefaults.favoritesKey)
        }
    }
}
