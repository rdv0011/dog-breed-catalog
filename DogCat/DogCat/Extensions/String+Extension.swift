//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation

extension String {
    /// Appends a relating part to a path string
    /// Prepends with an extra ```/``` if it does not exists
    func appendingPathComponents(_ pathComponent: String) -> String {
        guard pathComponent.count > 0 else {
            return self
        }
        let path = (self as NSString).appendingPathComponent(pathComponent)
        return path.first == "/" ? path : "/\(path)"
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    func stripping() -> [String] {
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = self.trimmingCharacters(in: whitespaceCharacterSet)
        return strippedString.components(separatedBy: " ") as [String]
    }
}
