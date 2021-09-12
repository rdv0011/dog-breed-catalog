//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation

/// Incapsulates all string as constants for easier and more efficient access from the code
///
/// - Note: String constant names have three groups divided by underscore delimiter:
/// [screen name]_[element name]_[elements property name]
/// breedNames_favoritesButton_title
/// The last part [elements property name] is optional if a translation is supposed to be used in for example UILabel element
/// - Tag: Localized
public final class Localized {
    /// Breeds
    public class var breedNamesScreenTitle: String { Localized.translate(Self.localizableTableName, "breedNames_screen_title")
    }
    /// Favorites
    public class var breedNamesFavoritesButtonTitle: String { Localized.translate(Self.localizableTableName, "breedNames_favoritesButton_Title")
    }
    /// Favorites
    public class var favoritesScreenTitle: String { Localized.translate(Self.localizableTableName, "favorites_screen_title")
    }
    /// Breed name
    public class var favoritesSearchBarPlaceholder: String { Localized.translate(Self.localizableTableName, "favorites_searchBar_placeholder")
    }
    /// No results
    public class var favoritesScreenNoResults: String { Localized.translate(Self.localizableTableName, "favorites_screen_noResults")
    }
    /// No data
    public class var generalNetworkingNoData: String { Localized.translate(Self.localizableTableName, "generalNetworking_noData")
    }
    /// Unrecoverable error. Pull to refresh later.
    public class var generalNetworkingUnrecoverableError: String { Localized.translate(Self.localizableTableName, "generalNetworking_unrecoverableError")
    }
    /// No network. Automatically re-try.
    public class var generalNetworkingNoNetwork: String { Localized.translate(Self.localizableTableName, "generalNetworking_noNetwork")
    }
}

/// A locale might be mocked for unit testing using ```locale``` variable
extension Localized {
    // Use a current locale by default
    public static var locale: (() -> Locale) = { Locale.current }
    static let bundle: Bundle = {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle(for: Localized.self)
#endif
    }()
    private static let languageBundleFileType = "lproj"
    private static let localizableTableName = "Localizable"
    private static let fallbackLocaleIdentifier = "en"

    private static func translate(_ table: String, _ key: String, _ args: CVarArg...) -> String {

        let locale = locale()
        let localeIdentifiers = [
            locale.identifier.replacingOccurrences(of: "_", with: "-"),
            fallbackLocaleIdentifier
        ]
        guard let (chosenLocaleIdentifier, bundle) = localeIdentifiers
                .compactMap({ bundle(for: $0) })
                .first else {
            return "[\(key)]"
        }
        // Translate string
        let translation = NSLocalizedString(key,
                                            tableName: table,
                                            bundle: bundle,
                                            comment: "")
        guard translation != key else {
            return "[\(key)]"
        }
        // Place string arguments
        return String(format: translation,
                      locale: Locale(identifier: chosenLocaleIdentifier),
                      arguments: args)
    }

    private static func bundle(for localeIdentifier: String) -> (String, Bundle)? {
        // Find a correct language bundle
        guard
            let languageBundlePath = bundle.path(forResource: localeIdentifier,
                                                 ofType: languageBundleFileType),
            let languageBundle = Bundle(path: languageBundlePath)
        else {
            return nil
        }
        return (localeIdentifier, languageBundle)
    }
}
