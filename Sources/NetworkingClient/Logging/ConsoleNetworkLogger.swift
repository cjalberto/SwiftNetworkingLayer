import Foundation

/// A `NetworkLogger` that prints a one-line summary of every request to the console.
///
/// Headers in `redactedHeaders` (matched case-insensitively) are replaced with `<redacted>`
/// before printing. Defaults to the headers this library itself can set — `Authorization`
/// (`AuthTokenProvider`) and `api-key` (`ServerFactory`) — plus `Cookie`/`Set-Cookie`; add
/// your own (e.g. a custom session header) via the initializer.
public struct ConsoleNetworkLogger: NetworkLogger {
    /// Whether request/response bodies are printed as text, or only their size.
    public enum BodyLoggingPolicy {
        /// Never print body content — only its byte count. Safe default: request/response
        /// bodies can contain passwords, tokens, or other data you don't want in a console
        /// log or a device's system log.
        case never

        /// Print the body as best-effort UTF-8 text. Intended for local debugging only.
        case always
    }

    private let redactedHeaders: Set<String>
    private let bodyLoggingPolicy: BodyLoggingPolicy
    private let print: (String) -> Void

    public init(
        redactedHeaders: Set<String> = ["Authorization", "api-key", "Cookie", "Set-Cookie"],
        bodyLoggingPolicy: BodyLoggingPolicy = .never,
        print: @escaping (String) -> Void = { Swift.print($0) }
    ) {
        self.redactedHeaders = Set(redactedHeaders.map { $0.lowercased() })
        self.bodyLoggingPolicy = bodyLoggingPolicy
        self.print = print
    }

    public func log(_ event: NetworkLogEvent) {
        print(description(for: event))
    }

    /// Builds the line `log(_:)` prints for `event`. Exposed separately so the redaction
    /// and formatting logic can be unit-tested without capturing stdout.
    public func description(for event: NetworkLogEvent) -> String {
        switch event {
        case .willSend(let request):
            return "→ \(method(of: request)) \(url(of: request)) \(headerDescription(request.allHTTPHeaderFields))"

        case .didReceive(let request, let response, let data, let duration):
            return "← \(response.statusCode) \(url(of: request)) (\(bodyDescription(data)), \(milliseconds(duration)))"

        case .didFail(let request, let error, let duration):
            return "✕ \(url(of: request)) failed after \(milliseconds(duration)): \(error.localizedDescription)"
        }
    }

    private func method(of request: URLRequest) -> String {
        request.httpMethod ?? "GET"
    }

    private func url(of request: URLRequest?) -> String {
        request?.url?.absoluteString ?? "<unknown URL>"
    }

    private func milliseconds(_ duration: TimeInterval) -> String {
        String(format: "%.0fms", duration * 1000)
    }

    private func headerDescription(_ headers: [String: String]?) -> String {
        guard let headers = headers, !headers.isEmpty else { return "[]" }
        let pairs = headers.map { key, value -> String in
            let displayValue = redactedHeaders.contains(key.lowercased()) ? "<redacted>" : value
            return "\(key): \(displayValue)"
        }.sorted()
        return "[\(pairs.joined(separator: ", "))]"
    }

    private func bodyDescription(_ data: Data) -> String {
        switch bodyLoggingPolicy {
        case .never:
            return "\(data.count) bytes"
        case .always:
            return String(data: data, encoding: .utf8) ?? "\(data.count) bytes (not UTF-8)"
        }
    }
}
