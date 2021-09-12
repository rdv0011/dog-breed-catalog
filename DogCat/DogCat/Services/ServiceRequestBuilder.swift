//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// Provides a relative path for an endpoint
protocol ServiceEndpointProviding {
    func path() -> String
}

/// Builds a specific API Url request based on arguments
protocol ServiceRequestBuilding {
    func endpointAdded() -> ServiceRequestBuilding
    // Get result URL request object based on the previously configured parameters
    func resultRequest() -> URLRequest
}

class ServiceRequestBuilder: ServiceRequestBuilding {
    var urlComponents: URLComponents

    init(baseURL: URL) {
        guard let urlComponents = URLComponents(url: baseURL,
                                                resolvingAgainstBaseURL: true) else {
            fatalError("Failed to create URLComponents \(baseURL)")
        }

        self.urlComponents = urlComponents
    }

    func endpointAdded() -> ServiceRequestBuilding {
        fatalError("Not implemented")
    }

    func resultRequest() -> URLRequest {
        // Normally it should be possible to get a url
        guard let resultURL = urlComponents.url else {

            fatalError("Failed to build URL: \(urlComponents)")
        }

        return URLRequest(url: resultURL)
    }
}
