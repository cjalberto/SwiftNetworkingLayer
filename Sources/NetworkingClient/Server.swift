import Foundation

/// The server a `Networking` instance talks to: a base URL, an optional environment
/// path segment, and headers that must be sent on every request (e.g. an API key).
public struct Server {
    let url: String
    let environment: String
    let mandatoryHeaders: [String: String]

    /// The base URL including the environment segment, if any.
    var baseURL: String {
        if !self.environment.isEmpty {
            return "\(self.url)/\(self.environment)/"
        }
        return "\(self.url)/"
    }

    fileprivate init(url: String, environment: String, mandatoryHeaders: [String: String]) {
        self.url = url
        self.environment = environment
        self.mandatoryHeaders = mandatoryHeaders
    }
}

/// Creates `Server` instances, optionally attaching an API key or other mandatory headers.
public class ServerFactory {
    /// Creates a `Server` for the given environment and base URL.
    ///
    /// - Parameters:
    ///   - environment: A path segment appended after the base URL (e.g. `"staging"`). Pass `""` for none.
    ///   - baseURL: The server's base URL, without a trailing slash.
    ///   - apiKey: If provided, sent as the `api-key` header on every request made against this server.
    ///   - additionalHeaders: Extra headers sent on every request made against this server.
    public static func createServer(for environment: String, baseURL: String, apiKey: String? = nil, additionalHeaders: [String: String] = [:]) -> Server {
        var headers = additionalHeaders

        if let apiKey = apiKey {
            headers["api-key"] = apiKey
        }

        return Server(url: baseURL, environment: environment, mandatoryHeaders: headers)
    }
}
