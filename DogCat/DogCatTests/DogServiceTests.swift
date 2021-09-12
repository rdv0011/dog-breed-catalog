//
// Copyright © 2019 Robert Bosch GmbH. All rights reserved. 
    

import XCTest
import Combine
@testable import DogCat

class DogServiceTests: XCTestCase {
    private var dogService: DogServicable!
    private var subscriptions = Set<AnyCancellable>()
    private var breedsFixtureData: Data?
    private let baseUrlString = DogServiceBaseUrl.dev.rawValue

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let sessionConfiguration: URLSessionConfiguration = .default
        // Register url protocol mock
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let urlSession = URLSession(configuration: sessionConfiguration)
        let configuration = DogService.Configuration(baseUrl: .dev,
                                                     urlSession: urlSession,
                                                     jsonDecoder: JSONDecoder())
        dogService = DogService(configuration: configuration,
                                connectionMonitoring: NetworkConnectionMonitorMock())
        // Data fixture
        breedsFixtureData = textFileData(contentsOf: "BreedsFixtureJson")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testReceivingAllBreeds() throws {
        // Set output data for a mocked part
        URLProtocolMock.jsonData = breedsFixtureData
        URLProtocolMock.responseWithStatusCode(code: 200,
                                               baseUrlString: baseUrlString)

        let allBreedFetched = expectation(description: "Fetching all breeds")
        dogService
            .allBreeds()
            .sink { completion in
                if case .failure = completion {
                    XCTFail("Failed: \(completion)")
                }
                allBreedFetched.fulfill()
            } receiveValue: { breeds in
                XCTAssertEqual(breeds.count, 2)
            }
            .store(in: &subscriptions)
        wait(for: [allBreedFetched], timeout: 1)
    }

    func testJsonIncorrectFormat() throws {
        // Set output data for a mocked part
        URLProtocolMock.jsonData = Data()
        URLProtocolMock.responseWithStatusCode(code: 200,
                                               baseUrlString: baseUrlString)

        let failedToParseErrorReceived = expectation(description: "Fetching all breeds")
        dogService
            .allBreeds()
            .sink { completion in
                if case let .failure(error) = completion {
                    if case .failedToParse = error {
                        failedToParseErrorReceived.fulfill()
                    } else {
                        XCTFail("Failed: \(completion)")
                    }
                }
            } receiveValue: { breeds in
                XCTFail("Unexpected output: \(breeds)")
            }
            .store(in: &subscriptions)
        wait(for: [failedToParseErrorReceived], timeout: 1)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
