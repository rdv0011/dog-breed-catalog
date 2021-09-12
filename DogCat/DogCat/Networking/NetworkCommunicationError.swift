//
// Copyright © 2021 Dmitry Rybakov. All rights reserved. 

import Foundation

/// Represents networking related errors
enum NetworkCommunicationError: Error {
    /// Errors related to the underling OS networking system
    case transportError(Error)
    /// Various HTTP non 2xx  errors that come from the backend
    case serverSideError(statusCode: Int)
    /// Triggered when there is no HTTP status code available for some reason
    case unexpectedResponse
    /// Failed to parse json object from the backend
    case failedToParse(Error)
}
