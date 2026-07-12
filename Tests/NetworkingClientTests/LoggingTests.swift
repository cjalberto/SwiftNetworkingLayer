import XCTest
@testable import NetworkingClient

final class LoggingTests: XCTestCase {

    private func request(headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://example.com/login")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        return request
    }

    // MARK: - Header redaction

    func testRedactsDefaultSensitiveHeaders() {
        let logger = ConsoleNetworkLogger()
        let description = logger.description(for: .willSend(request(headers: [
            "Authorization": "Bearer super-secret",
            "api-key": "abc123",
            "Cookie": "session=xyz",
            "X-Request-Id": "42"
        ])))

        XCTAssertFalse(description.contains("super-secret"))
        XCTAssertFalse(description.contains("abc123"))
        XCTAssertFalse(description.contains("xyz"))
        XCTAssertTrue(description.contains("X-Request-Id: 42")) // Not sensitive, left as-is.
    }

    func testHeaderRedactionIsCaseInsensitive() {
        let logger = ConsoleNetworkLogger()
        let description = logger.description(for: .willSend(request(headers: ["AUTHORIZATION": "Bearer secret"])))

        XCTAssertFalse(description.contains("secret"))
    }

    func testCustomRedactedHeadersAreHonored() {
        let logger = ConsoleNetworkLogger(redactedHeaders: ["X-Session-Token"])
        let description = logger.description(for: .willSend(request(headers: [
            "X-Session-Token": "should-be-hidden",
            "Authorization": "should-now-be-visible-since-defaults-were-replaced"
        ])))

        XCTAssertFalse(description.contains("should-be-hidden"))
        XCTAssertTrue(description.contains("should-now-be-visible-since-defaults-were-replaced"))
    }

    // MARK: - Body logging policy

    func testNeverLogsBodyContentByDefault() {
        let logger = ConsoleNetworkLogger()
        let response = HTTPURLResponse(url: URL(string: "https://example.com/login")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let description = logger.description(for: .didReceive(
            request: request(headers: [:]),
            response: response,
            data: Data("{\"password\":\"secret\"}".utf8),
            duration: 0.1
        ))

        XCTAssertFalse(description.contains("secret"))
        XCTAssertTrue(description.contains("21 bytes"))
    }

    func testAlwaysPolicyPrintsBodyContent() {
        let logger = ConsoleNetworkLogger(bodyLoggingPolicy: .always)
        let response = HTTPURLResponse(url: URL(string: "https://example.com/login")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let description = logger.description(for: .didReceive(
            request: request(headers: [:]),
            response: response,
            data: Data("{\"token\":\"abc\"}".utf8),
            duration: 0.1
        ))

        XCTAssertTrue(description.contains("{\"token\":\"abc\"}"))
    }

    // MARK: - Event formatting

    func testDidFailDescriptionIncludesTheURLAndErrorMessage() {
        let logger = ConsoleNetworkLogger()
        let description = logger.description(for: .didFail(
            request: request(headers: [:]),
            error: URLError(.notConnectedToInternet),
            duration: 0.25
        ))

        XCTAssertTrue(description.contains("example.com/login"))
        XCTAssertTrue(description.contains("250ms"))
    }
}
