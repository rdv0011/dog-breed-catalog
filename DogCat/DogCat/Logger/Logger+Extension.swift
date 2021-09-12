//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation

extension LogCategory {
    public static let favoritesStore = LogCategory(category: "favoritesStore",
                                                   defaultLogLevel: .verbose)
    public static let breedImages = LogCategory(category: "breedImages",
                                                   defaultLogLevel: .verbose)
    public static let networking = LogCategory(category: "networking",
                                                   defaultLogLevel: .verbose)
}
