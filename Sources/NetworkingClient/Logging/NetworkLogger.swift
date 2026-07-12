import Foundation

/// A request lifecycle event `Networking` reports to an injected `NetworkLogger`.
public enum NetworkLogEvent {
    /// About to send `request`.
    case willSend(URLRequest)

    /// `request` came back with `response` and `data` after `duration` seconds.
    case didReceive(request: URLRequest, response: HTTPURLResponse, data: Data, duration: TimeInterval)

    /// `request` failed with `error` after `duration` seconds (transport failure, or the
    /// request could never be sent at all — e.g. an invalid URL).
    case didFail(request: URLRequest?, error: Error, duration: TimeInterval)
}

/// Observes `Networking`'s request lifecycle. Injected as `nil` by default, so logging has
/// zero cost unless you explicitly opt in.
///
/// A conforming type receives the raw `URLRequest`/`Data`, including any headers set on it
/// (e.g. `Authorization`, `api-key`) — redact anything sensitive before writing it anywhere.
/// `ConsoleNetworkLogger` shows one way to do this.
public protocol NetworkLogger {
    func log(_ event: NetworkLogEvent)
}
