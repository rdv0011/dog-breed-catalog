//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation
import Combine
import UIKit

final class DogService: DogServicable {
    struct Configuration {
        let baseUrl: DogServiceBaseUrl
        let urlSession: URLSession
        let jsonDecoder: JSONDecoder
    }

    // MARK:- Dependencies
    @Injectable private var configuration: Configuration
    @Injectable private var connectionMonitoring: NetworkConnectionMonitoring
    @Injectable private var cache: ImageCache

    init() {
    }

    func allBreeds() -> AnyPublisher<[String], NetworkCommunicationError> {
        makeAllBreedsRequestPublisher()
            .publisher()
            .map { rootObject -> [String] in
                Array(rootObject.breeds.keys).sorted()
            }
            .eraseToAnyPublisher()
    }

    func allImageUrls(for breedName: String) -> AnyPublisher<[URL], NetworkCommunicationError> {
        makeAllImageUrlsRequestPublisher(breedName)
            .publisher()
            .map { rootObject -> [URL] in
                rootObject.imageUrls
            }
            .eraseToAnyPublisher()
    }

    func randomImageUrl(for breedName: String) -> AnyPublisher<URL, NetworkCommunicationError> {
        /// Send an asynchronous request. Once image is downloaded publish the result
        makeRandomImageUrlRequestPublisher(breedName)
            .publisher()
            .map { rootObject -> URL in
                rootObject.imageUrl
            }
            .eraseToAnyPublisher()
    }

    func image(from url: URL) -> AnyPublisher<UIImage?, Never> {
        /// Send an asynchronous request. Once image is downloaded publish the result
        let dataRequest =
            DogServiceRequestBuildingDirector(builder:                                                    DogServiceDownloadingRequestBuilder(downloadingUrl: url))
            .makeDownloadingDataRequest()
        return ImageCashableNetworkRequest(request: dataRequest,
                                    urlSession: configuration.urlSession,
                                    cache: cache)
            .publisher()
            // Replace failed requests with nil which will be interpreted somehow in the UI
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    private func makeAllBreedsRequestPublisher() -> DecodableNetworkRequest<BreedNames> {
        (makeDecodableRequest(request: makeJsonRequest(for: DogServiceEndpoints.allBreeds)) as DecodableNetworkRequest<BreedNames>)
    }

    private func makeAllImageUrlsRequestPublisher(_ breedName: String) -> DecodableNetworkRequest<BreedImageUrls> {
        (makeDecodableRequest(request: makeJsonRequest(for: DogServiceEndpoints.allImageUrls(breedName))) as DecodableNetworkRequest<BreedImageUrls>)
    }

    private func makeRandomImageUrlRequestPublisher(_ breedName: String) -> DecodableNetworkRequest<BreedRandomImageUrl> {
        (makeDecodableRequest(request: makeJsonRequest(for: DogServiceEndpoints.randomImageUrl(breedName))) as DecodableNetworkRequest<BreedRandomImageUrl>)
    }

    private func makeJsonRequest(for endpoint: ServiceEndpointProviding) -> URLRequest {
        let builder = DogServiceJsonRequestBuilder(serviceBaseUrl: configuration.baseUrl,
                                                  endpoint: endpoint)
        return DogServiceRequestBuildingDirector(builder: builder)
            .makeJsonRequest()
    }

    private func makeDecodableRequest<T: Decodable>(request: URLRequest) -> DecodableNetworkRequest<T> {
        DecodableNetworkRequest<T>(request: request,
                                   urlSession: configuration.urlSession,
                                   jsonDecoder: configuration.jsonDecoder,
                                   connectionMonitoring: connectionMonitoring)
    }
}
