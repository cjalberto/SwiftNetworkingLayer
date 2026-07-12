import Foundation

/// Supplies the bearer token `Networking` attaches to every request, and refreshes it
/// when a request comes back `401 Unauthorized`.
///
/// Completion-handler based (rather than `async`) so it can be used from `Networking`'s
/// completion-handler API without raising that API's availability floor; the async and
/// Combine variants wrap these same callbacks internally.
public protocol AuthTokenProvider {
    /// The current token to send as `Authorization: Bearer <token>`. Called before every
    /// request. Call `completion(nil)` to send the request without an `Authorization` header.
    func currentToken(completion: @escaping (String?) -> Void)

    /// Called once, after a request comes back `401 Unauthorized`, to obtain a fresh token
    /// before retrying the request exactly one more time. Call `completion(nil)` to give up
    /// without retrying, surfacing the original 401 to the caller.
    func refreshToken(completion: @escaping (String?) -> Void)
}
