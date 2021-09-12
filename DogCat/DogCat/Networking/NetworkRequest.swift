//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.

import Foundation
import Combine
import UIKit

/// Defines three main parts of the networking protocol:
/// - ```Response```
/// - ```Error``` that might happen when communicating
/// - ```publisher()``` to get the result
/// - Tag: NetworkRequest
protocol NetworkRequest {
    associatedtype Response
    associatedtype Error: Swift.Error

    func publisher() -> AnyPublisher<Response, Error>
}

/// Type erasure for [NetworkRequest](x-source-tag://NetworkRequest) type
/// Might be used to organize a queue of the requests for different purposes like prioritizing
/// - Tag: AnyNetworkRequest
struct AnyNetworkRequest<Response, Error: Swift.Error> {

    var wrappedPublisher: () -> AnyPublisher<Response, Error>

    init<T: NetworkRequest>(_ wrappedRequest: T) where T.Response == Response,
                                                       T.Error == Error {
        self.wrappedPublisher = wrappedRequest.publisher
    }

    func publisher() -> AnyPublisher<Response, Error> {
        wrappedPublisher()
    }
}

struct DataNetworkRequest: NetworkRequest {
    typealias Response = Data
    typealias Error = NetworkCommunicationError

    let request: URLRequest
    let urlSession: URLSession

    /// Creates a publisher for a new network request
    func publisher() -> AnyPublisher<Response, Error> {
        urlSession.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard
                    let response = response as? HTTPURLResponse, // is there HTTP response
                    200 ..< 300 ~= response.statusCode           // is statusCode 2XX
                else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    if statusCode > 0 {
                        throw NetworkCommunicationError.serverSideError(statusCode: statusCode)
                    } else {
                        throw NetworkCommunicationError.unexpectedResponse
                    }
                }
                return data
            }
            .mapError { error in
                // Since serverSide errors are wrapped earlier the transport errors left only
                error as? NetworkCommunicationError ?? NetworkCommunicationError.transportError(error)
            }
            .eraseToAnyPublisher()
    }
}

/// Sends provided networks requests.
///
/// Can re-try a network request if it fails. It does ```retriesCount``` attempts with ```retryDelaySeconds``` sec delay interval in-between
/// - Note: if ```connectionMonitoring``` is set it waits until the network is available and re-try a network request automatically
/// Which means that a delay between making a request and receiving a response might be longer than specified by ```connectTimeout```
/// So, on the UI level it make sense to monitor the connection state in parallel and inform the user correspondingly
/// - Tag: DataRetriableNetworkRequest
struct DataRetriableNetworkRequest: NetworkRequest {
    typealias Response = Data
    typealias Error = NetworkCommunicationError
    typealias DataTaskResult = Result<Data, Swift.Error>

    private static let retriesCount = 3
    private static let retryDelaySeconds: TimeInterval = 3

    let request: URLRequest
    let urlSession: URLSession
    let connectionMonitoring: NetworkConnectionMonitoring?

    func publisher() -> AnyPublisher<Response, Error> {
        DataNetworkRequest(request: request, urlSession: urlSession)
            .publisher()
            .map { data in .success(data) }
            .catch { [connectionMonitoring] (error: Swift.Error) -> AnyPublisher<DataTaskResult, Swift.Error> in
                Self.handleRetriableError(error: error,
                                     connectionMonitoring: connectionMonitoring)
            }
            .retry(Self.retriesCount)
            .tryMap { result in
                // Result -> Result.Success or emit Result.Failure
                try result.get()
            }
            .mapError { error in
                // Since serverSide errors are wrapped earlier the transport errors left only
                error as? NetworkCommunicationError ?? NetworkCommunicationError.transportError(error)
            }
            .eraseToAnyPublisher()
    }

    private static func handleRetriableError(error: Swift.Error,
                                      connectionMonitoring: NetworkConnectionMonitoring?) -> AnyPublisher<DataTaskResult, Swift.Error> {
        guard let networkError = error as? NetworkCommunicationError else {
            return Self.handleTransportError(error: error,
                                        connectionMonitoring: connectionMonitoring)
        }

        switch networkError {
        case .serverSideError:
            // Re-try request after a delay
            return Fail(error: networkError)
                .delay(for: .seconds(retryDelaySeconds), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        case .transportError(let error):
            // It will wait until a connection is re-established if a transport error happens because of that
            return Self.handleTransportError(error: error,
                                        connectionMonitoring: connectionMonitoring)
        default:
            return Just(.failure(error))
                .setFailureType(to: Swift.Error.self)
                .eraseToAnyPublisher()
        }
    }

    private static func isNoConnection(code: URLError.Code) -> Bool {
        code == URLError.notConnectedToInternet ||
            code == URLError.networkConnectionLost ||
            // NOTE:- The following have not been tested with Reachability
            // Also they a re-triable by with help from the user, some interaction in UI is needed
            code == URLError.dataNotAllowed ||
            code == URLError.callIsActive ||
            code == URLError.internationalRoamingOff
    }

    private static func handleTransportError(error: Swift.Error,
                                      connectionMonitoring: NetworkConnectionMonitoring?) -> AnyPublisher<DataTaskResult, Swift.Error> {

        // If reachability publisher is available then try to wait until the network is available again and re-try
        if let connectionMonitoring = connectionMonitoring,
           let urlError = error as? URLError,
           isNoConnection(code: urlError.code) {
            return connectionMonitoring
                .connectionAvailable()
                .flatMap { _ in
                    // Re-try request immediately
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else {

            return Just(.failure(error))
                .setFailureType(to: Swift.Error.self)
                .eraseToAnyPublisher()
        }
    }
}

/// Sends a network request and decode a JSON object from a response
/// - Note: Behaves in the same way as [DataRetriableNetworkRequest](x-source-tag://DataRetriableNetworkRequest)
/// - Tag: DecodableNetworkRequest
struct DecodableNetworkRequest<T: Decodable>: NetworkRequest {
    typealias Response = T
    typealias Error = NetworkCommunicationError

    let request: URLRequest
    let urlSession: URLSession
    let jsonDecoder: JSONDecoder
    let connectionMonitoring: NetworkConnectionMonitoring?

    init(request: URLRequest,
         urlSession: URLSession,
         jsonDecoder: JSONDecoder,
         connectionMonitoring: NetworkConnectionMonitoring? = nil) {
        self.request = request
        self.urlSession = urlSession
        self.jsonDecoder = jsonDecoder
        self.connectionMonitoring = connectionMonitoring
    }

    func publisher() -> AnyPublisher<Response, Error> {
        DataRetriableNetworkRequest(request: request,
                                    urlSession: urlSession,
                                    connectionMonitoring: connectionMonitoring)
            .publisher()
            .decode(type: T.self, decoder: jsonDecoder)
            .mapError { error in
                if error is DecodingError {
                    return NetworkCommunicationError.failedToParse(error)
                } else {
                    return error as? NetworkCommunicationError ?? NetworkCommunicationError.transportError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

/// Sends a request to download an image and cache it once received from the backend
/// - Note: The actual network will not be send if the requested image already cached.
/// Instead this cached image will be returned immediately.
/// - Tag: ImageCashableNetworkRequest
struct ImageCashableNetworkRequest: NetworkRequest {
    typealias Response = UIImage?
    typealias Error = NetworkCommunicationError

    let request: URLRequest
    let urlSession: URLSession
    let cache: ImageCache
    let connectionMonitoring: NetworkConnectionMonitoring?

    init(request: URLRequest,
         urlSession: URLSession,
         cache: ImageCache,
         connectionMonitoring: NetworkConnectionMonitoring? = nil) {
        self.request = request
        self.urlSession = urlSession
        self.cache = cache
        self.connectionMonitoring = connectionMonitoring
    }

    private static func makeRequestPublisher(imageUrl: URL, request: URLRequest,
                                      urlSession: URLSession,
                                      cache: ImageCache,
                                      connectionMonitoring: NetworkConnectionMonitoring?) -> AnyPublisher<Response, NetworkCommunicationError> {
        DataRetriableNetworkRequest(request: request,
                                    urlSession: urlSession,
                                    connectionMonitoring: connectionMonitoring)
            .publisher()
            .map { data -> Response in
                UIImage(data: data)
            }
            .handleEvents(receiveOutput: { image in
                guard let image = image else {
                    log.error(.networking, "Failed to create image from url: \(imageUrl)")
                    return
                }
                cache[imageUrl] = image
            })
            .eraseToAnyPublisher()
    }

    func publisher() -> AnyPublisher<Response, Error> {
        guard let imageUrl = request.url else {
            fatalError("Failed to get url from \(request)")
        }
        /// Send an asynchronous request. Once image is downloaded publish the result
        return Just(imageUrl)
            .flatMap { [cache, connectionMonitoring] imageUrl -> AnyPublisher<Response, NetworkCommunicationError> in
                guard let image = cache[imageUrl] else {
                    // Download image asynchronously and cache it
                    return Self.makeRequestPublisher(imageUrl: imageUrl,
                                                request: request,
                                                urlSession: urlSession,
                                                cache: cache,
                                                connectionMonitoring: connectionMonitoring)
                }
                // Return decompressed cached image to avoid UI stuttering
                return Just(image)
                    .setFailureType(to: NetworkCommunicationError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
