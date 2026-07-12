import Foundation

/// Describes a single API request: its HTTP method, path, body, headers, and how to
/// decode its response.
public protocol Endpoint {
    /// The `Decodable` type the response body is expected to decode into.
    associatedtype requestType: Decodable

    /// The HTTP method to use (GET, POST, etc.).
    var method: HTTPMethod { get }

    /// The path appended to the server's base URL.
    var path: String { get }

    /// The request body, if any.
    var body: Data? { get }

    /// Headers specific to this endpoint. These take priority over the server's
    /// `mandatoryHeaders` when both define the same header.
    var headers: [String: String]? { get }

    /// The strategy used to decode the response body into `requestType`.
    var decoder: ResponseDecodable { get }

    /// This endpoint's own request configuration (timeout, cache policy, etc.), if it
    /// needs to override the `Networking` client's default. Returns `nil` to inherit
    /// the client's configuration.
    var configuration: RequestConfiguration? { get }

    /// Builds the `URLRequest` for this endpoint against the given `server`, applying `configuration`.
    func urlRequest(server: Server, configuration: RequestConfiguration) -> URLRequest?
}

extension Endpoint {
    public var configuration: RequestConfiguration? { nil }

    public func urlRequest(server: Server, configuration: RequestConfiguration = DefaultRequestConfiguration()) -> URLRequest? {
        guard let url = URL(string: server.baseURL + path) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        // Endpoint headers take priority over the server's mandatory headers.
        request.allHTTPHeaderFields = server.mandatoryHeaders.merging(headers ?? [:]) { _, endpointValue in endpointValue }

        request.timeoutInterval = configuration.timeoutInterval
        request.cachePolicy = configuration.cachePolicy
        request.allowsCellularAccess = configuration.allowsCellularAccess
        request.httpShouldHandleCookies = configuration.httpShouldHandleCookies
        // Only available from iOS 13 / macOS 10.15; this package's minimum deployment target is iOS 12.
        if #available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *) {
            request.allowsExpensiveNetworkAccess = configuration.allowsExpensiveNetworkAccess
            request.allowsConstrainedNetworkAccess = configuration.allowsConstrainedNetworkAccess
        }

        return request
    }
}

extension Endpoint {
    /// Converts a dictionary of query parameters into a percent-encoded query string,
    /// e.g. `["q": "a b"]` becomes `"q=a%20b"`. Does not include a leading `?` or `&`.
    public func queryString(from parameters: [String: Any]) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "&=+")

        let keyValuePairs = parameters.map { key, value -> String in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? key
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? "\(value)"
            return "\(encodedKey)=\(encodedValue)"
        }
        return keyValuePairs.joined(separator: "&")
    }
}
