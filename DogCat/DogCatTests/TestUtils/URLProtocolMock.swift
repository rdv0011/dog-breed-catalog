//
// Copyright © 2021 Dmitry Rybakov. All rights reserved.
    

import Foundation

public final class URLProtocolMock: URLProtocol {
    public enum ResponseType {
        case error(Error)
        case success(HTTPURLResponse)
    }
    public static var isEnabled: Bool = true
    public static var responseType: ResponseType = .error(URLError(.cancelled))
    public static var jsonData: Data?
    public static var willStartLoadingRequestHandler: ((URLRequest) -> Void)?

    override public class func canInit(with request: URLRequest) -> Bool {
        return Self.isEnabled
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public class func requestIsCacheEquivalent(_ aRequest: URLRequest, to bRequest: URLRequest) -> Bool {
        return false
    }

    override public func startLoading() {
        Self.willStartLoadingRequestHandler?(self.request)
        switch Self.responseType {
        case .success(let response):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = Self.jsonData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        case .error(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {
        // Nothing to do
    }
}

extension URLProtocolMock {
    public static func responseWithStatusCode(code: Int, baseUrlString: String) {
        Self.responseType = .success(HTTPURLResponse(url: URL(string: baseUrlString)!,
                                                statusCode: code,
                                                httpVersion: nil,
                                                headerFields: ["Content-Type": "application/json"])!)
    }

    public static func responseWithTimeout() {
        let error = URLError(.timedOut, description: "Connection timeout")
        Self.responseType = .error(error)
    }
}

private extension URLError {
    init(_ code: URLError.Code, description: String?) {
        guard let description = description else {
            self.init(code, userInfo: [:])

            return
        }
        self.init(code, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
