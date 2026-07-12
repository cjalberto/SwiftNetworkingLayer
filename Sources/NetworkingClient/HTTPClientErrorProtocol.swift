import Foundation

/// Sentinel codes `Networking` uses for failures it detects before receiving an HTTP
/// response from the server (e.g. building the request, or decoding its body).
///
/// These are negative by design: no valid HTTP status code is negative, so they can
/// never collide with a real status code returned by the server (unlike reusing values
/// such as 400/421/422/500 to mean both an internal failure and a server response).
public enum InternalFailureCode: Int {
    case invalidURL = -1
    case noResponse = -2
    case noData = -3
    case decodingFailed = -4
}

/// A typed error that `Networking` reports request failures through. Conforming types
/// decide how HTTP status codes and internal/transport failures map onto their own cases.
public protocol HTTPClientErrorProtocol: Error {
    var localizedDescription: String { get }
    var errorCode: Int { get }

    /// Maps either a real HTTP status code from the server, or one of the negative
    /// `InternalFailureCode` values for failures detected before a response was received.
    static func map(statusCode: Int) -> Self

    /// Maps a transport-level error (no connection, timeout, cancelled, etc.), preserving
    /// its original information.
    static func map(underlyingError error: Error) -> Self
}
