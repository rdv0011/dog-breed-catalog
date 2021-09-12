//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import XCTest
import Foundation

extension XCTestCase {
    func textFileData(contentsOf fileName: String) -> Data? {
        guard let url = Bundle(for: type(of: self))
                .url(forResource: fileName, withExtension: "txt") else {
            fatalError("Failed to get a test file URL \(fileName)")
        }
        return try? Data(contentsOf: url)
    }
}
