//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// View model content state. Also contains the reason why a content in the view model is not available.
enum ViewModelContentAvailability {
    case yes
    case no(reason: String)

    var reason: String? {
        switch self {
        case .no(let reason):
            return reason
        default:
            return nil
        }
    }

    var available: Bool {
        switch self {
        case .yes:
            return true
        default:
            return false
        }
    }
}

/// View model content refreshing state
enum ViewModelContentRefreshingState {
    case ongoing
    case finished(contentAvailable: ViewModelContentAvailability?)

    var availableContent: ViewModelContentAvailability? {
        switch self {
        case .ongoing:
            return nil
        case .finished(let availability):
            return availability
        }
    }

    var isOngoing: Bool {
        switch self {
        case .ongoing:
            return true
        default:
            return false
        }
    }
}
