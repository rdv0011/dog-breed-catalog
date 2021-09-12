//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation

/// Build a http request to get some object from the backend
final class DogServiceJsonRequestBuilder: ServiceRequestBuilder {
    let endpoint: ServiceEndpointProviding

    init(serviceBaseUrl: DogServiceBaseUrl,
         endpoint: ServiceEndpointProviding) {

        self.endpoint = endpoint

        super.init(baseURL: serviceBaseUrl.url())
    }

    override func endpointAdded() -> ServiceRequestBuilding {
        let basePath = urlComponents.path
        urlComponents.path = basePath.appendingPathComponents(endpoint.path())
        return self
    }
}

/// Is used to build http request to download a resource from the backend
final class DogServiceDownloadingRequestBuilder: ServiceRequestBuilder {
    init(downloadingUrl: URL) {
        super.init(baseURL: downloadingUrl)
    }
}

/// Accepts different types of request builders
/// - NOTE: Currently supports json and downloading requests
struct DogServiceRequestBuildingDirector {
    private let builder: ServiceRequestBuilding

    init(builder: ServiceRequestBuilding) {
        self.builder = builder
    }

    /// - Returns: a request which is used to get a json object from the backend
    func makeJsonRequest() -> URLRequest {
        builder
            .endpointAdded()
            .resultRequest()
    }

    /// - Returns: a requests that is used to download data from the backend
    func makeDownloadingDataRequest() -> URLRequest {
        builder
            .resultRequest()
    }
}
