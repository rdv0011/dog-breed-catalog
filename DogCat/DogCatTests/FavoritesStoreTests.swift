//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import XCTest
import Combine
import CombineExpectations

@testable import DogCat

class FavoritesStoreTests: XCTestCase {
    private var favoritesStore: FavoritesStoring!
    private let testImgUrl = URL(string: "https://test.com")!

    override func setUpWithError() throws {
        let favoritesStore = FavoriteStore()
        favoritesStore.removeAll()
        self.favoritesStore = favoritesStore
    }

    override func tearDownWithError() throws {
    }

    func testInitialPublishing() throws {
        let testBreed = Breed(imageUrl: testImgUrl,
                              breedName: "test")

        let recorder = favoritesStore
            .publisher(for: testBreed)
            .record()

        XCTAssertEqual(0, favoritesStore.all().count)

        let toggleValues = try wait(for: recorder.availableElements,
                                    timeout: 1)

        XCTAssertEqual(toggleValues, [false])
    }

    func testToggling() throws {
        let testBreed = Breed(imageUrl: testImgUrl,
                              breedName: "test")

        let recorder = favoritesStore
            .publisher(for: testBreed)
            // We are interested in two values after toggling
            .dropFirst()
            .record()

        // Force the storage to emit values
        favoritesStore
            .toggle(for: testBreed)

        XCTAssertEqual([testBreed], favoritesStore.all())

        favoritesStore
            .toggle(for: testBreed)

        XCTAssertEqual(0, favoritesStore.all().count)

        let toggleValues = try wait(for: recorder.availableElements,
                                    timeout: 1)

        XCTAssertEqual(toggleValues, [true,
                                      false])
    }
}
