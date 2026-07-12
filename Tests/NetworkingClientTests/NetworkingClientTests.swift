import XCTest
@testable import NetworkingClient

final class NetworkingClientTests: XCTestCase {
    let baseUrl = "https://example.com/api"
    var server: Server!
    var networking: Networking<HTTPClientError>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        server = ServerFactory.createServer(for: "", baseURL: baseUrl)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        networking = Networking<HTTPClientError>(provider: server, session: URLSession(configuration: configuration))
    }

    override func tearDownWithError() throws {
        MockURLProtocol.requestHandler = nil
        server = nil
        networking = nil
        try super.tearDownWithError()
    }

    private func stub(statusCode: Int = 200, body: Data?, error: Error? = nil) {
        MockURLProtocol.requestHandler = { request in
            if let error = error { throw error }
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
    }

    // MARK: - Success

    func testAsyncRequest() {
        stub(body: sampleEpisodeJSON)
        let expectation = expectation(description: "Async request expectation")

        networking.request(endpoint: MockEndpoint()) { result in
            switch result {
            case .success(let episodes):
                XCTAssertEqual(episodes.results.first?.name, "Sample")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Unexpected error: \(error.localizedDescription)")
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    @available(iOS 15.0, *)
    func testSyncRequest() async {
        stub(body: sampleEpisodeJSON)
        let result = await networking.request(endpoint: MockEndpoint())

        switch result {
        case .success(let episodes):
            XCTAssertEqual(episodes.results.first?.name, "Sample")
        case .failure(let error):
            XCTFail("Unexpected error: \(error.localizedDescription)")
        }
    }

    @available(iOS 13.0, *)
    func testCombineRequest() {
        stub(body: sampleEpisodeJSON)
        let expectation = XCTestExpectation(description: "Combine request expectation")
        var received: EpisodeResponse?

        let cancellable = networking.request(endpoint: MockEndpoint())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error.localizedDescription)")
                }
                expectation.fulfill()
            }, receiveValue: { received = $0 })

        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(received?.results.first?.name, "Sample")
        cancellable.cancel()
    }

    // MARK: - Errors: a real server status code must never be misread as an internal failure

    @available(iOS 15.0, *)
    func testHTTPErrorPreservesRealStatusCode() async {
        stub(statusCode: 404, body: Data("not found".utf8))
        let result = await networking.request(endpoint: MockEndpoint())

        switch result {
        case .success:
            XCTFail("Expected an error")
        case .failure(let error):
            guard case .requestFailed(let statusCode, _) = error else {
                return XCTFail("Expected .requestFailed, got \(error)")
            }
            XCTAssertEqual(statusCode, 404)
        }
    }

    @available(iOS 15.0, *)
    func testServerErrorStatusCodeIsNotMisreadAsInvalidURL() async {
        // Before the fix, a real 500 from the server was interpreted as the internal
        // "invalidURL" failure, because both reused the number 500.
        stub(statusCode: 500, body: Data("boom".utf8))
        let result = await networking.request(endpoint: MockEndpoint())

        switch result {
        case .success:
            XCTFail("Expected an error")
        case .failure(let error):
            guard case .requestFailed(let statusCode, _) = error else {
                return XCTFail("Expected .requestFailed(500, _), got \(error)")
            }
            XCTAssertEqual(statusCode, 500)
        }
    }

    @available(iOS 15.0, *)
    func testDecodingFailureMapsToDecodingFailed() async {
        stub(body: Data("{}".utf8)) // Valid JSON, but not shaped like EpisodeResponse
        let result = await networking.request(endpoint: MockEndpoint())

        switch result {
        case .success:
            XCTFail("Expected a decoding error")
        case .failure(let error):
            guard case .decodingFailed = error else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
        }
    }

    @available(iOS 15.0, *)
    func testTransportErrorPreservesUnderlyingInfo() async {
        stub(body: nil, error: URLError(.notConnectedToInternet))
        let result = await networking.request(endpoint: MockEndpoint())

        switch result {
        case .success:
            XCTFail("Expected a transport error")
        case .failure(let error):
            guard case .requestFailed(_, let message) = error else {
                return XCTFail("Expected .requestFailed, got \(error)")
            }
            XCTAssertFalse(message.isEmpty)
        }
    }

    // MARK: - Server / headers

    func testServerMandatoryHeadersAreAppliedToRequest() {
        let authenticatedServer = ServerFactory.createServer(
            for: "",
            baseURL: baseUrl,
            apiKey: "secret-key",
            additionalHeaders: ["X-Custom": "1"]
        )

        let request = MockEndpoint().urlRequest(server: authenticatedServer)

        XCTAssertEqual(request?.allHTTPHeaderFields?["api-key"], "secret-key")
        XCTAssertEqual(request?.allHTTPHeaderFields?["X-Custom"], "1")
    }

    func testEndpointHeadersOverrideServerMandatoryHeadersOnConflict() {
        let conflictingServer = ServerFactory.createServer(
            for: "",
            baseURL: baseUrl,
            additionalHeaders: ["Content-Type": "text/plain"]
        )

        let request = MockEndpoint().urlRequest(server: conflictingServer)

        XCTAssertEqual(request?.allHTTPHeaderFields?["Content-Type"], "application/json")
    }

    // MARK: - Query string

    func testQueryStringPercentEncodesValues() {
        let query = MockEndpoint().queryString(from: ["q": "a b&c"])
        XCTAssertEqual(query, "q=a%20b%26c")
    }

    // MARK: - Request configuration

    func testDefaultConfigurationAppliesURLRequestDefaults() {
        let request = MockEndpoint().urlRequest(server: server)

        XCTAssertEqual(request?.timeoutInterval, 60)
        XCTAssertEqual(request?.cachePolicy, .useProtocolCachePolicy)
    }

    func testExplicitConfigurationOverridesDefaultTimeout() {
        let request = MockEndpoint().urlRequest(server: server, configuration: ShortTimeoutConfiguration())

        XCTAssertEqual(request?.timeoutInterval, 5)
    }

    func testClientWideConfigurationIsAppliedToEveryRequest() {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, sampleEpisodeJSON)
        }

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let configuredNetworking = Networking<HTTPClientError>(
            provider: server,
            session: URLSession(configuration: sessionConfiguration),
            configuration: ShortTimeoutConfiguration()
        )

        let expectation = expectation(description: "client-wide configuration expectation")
        configuredNetworking.request(endpoint: MockEndpoint()) { _ in expectation.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(capturedRequest?.timeoutInterval, 5)
    }

    func testEndpointConfigurationOverridesClientWideConfiguration() {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, sampleEpisodeJSON)
        }

        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MockURLProtocol.self]
        let configuredNetworking = Networking<HTTPClientError>(
            provider: server,
            session: URLSession(configuration: sessionConfiguration),
            configuration: ShortTimeoutConfiguration() // client default: 5s
        )

        let expectation = expectation(description: "endpoint configuration expectation")
        configuredNetworking.request(endpoint: LongTimeoutEndpoint()) { _ in expectation.fulfill() } // endpoint overrides to 120s
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(capturedRequest?.timeoutInterval, 120)
    }
}

private let sampleEpisodeJSON = Data("""
{"info":{"count":1,"pages":1,"next":null,"prev":null},"results":[{"id":1,"name":"Sample","air_date":"December 2, 2013","episode":"S01E01","characters":[],"url":"https://example.com/1","created":"2017-11-10T12:56:33.798Z"}]}
""".utf8)

struct EpisodeResponse: Codable {
    let info: Info
    let results: [Episode]
}

struct Info: Codable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

struct Episode: Codable {
    let id: Int
    let name: String
    let airDate: String
    let episode: String
    let characters: [String]
    let url: String
    let created: String

    enum CodingKeys: String, CodingKey {
        case id, name, episode, characters, url, created
        case airDate = "air_date"
    }
}

// Mock Endpoint for testing
struct MockEndpoint: JSONEndpointBase {
    typealias requestType = EpisodeResponse
    var method: NetworkingClient.HTTPMethod = .get
    var path: String = "episode"
    var body: Data?
}

private struct ShortTimeoutConfiguration: RequestConfiguration {
    var timeoutInterval: TimeInterval { 5 }
}

private struct LongTimeoutConfiguration: RequestConfiguration {
    var timeoutInterval: TimeInterval { 120 }
}

/// An endpoint that overrides the client's default configuration with its own.
private struct LongTimeoutEndpoint: JSONEndpointBase {
    typealias requestType = EpisodeResponse
    var method: NetworkingClient.HTTPMethod = .get
    var path: String = "episode"
    var body: Data?
    var configuration: RequestConfiguration? { LongTimeoutConfiguration() }
}
