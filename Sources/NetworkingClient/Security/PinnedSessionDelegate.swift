import Foundation
import Security

/// A `URLSessionDelegate` that only trusts a server when both the system's own
/// certificate-chain validation *and* the injected `PinningPolicy` agree.
///
/// Build a `URLSession` with this delegate and inject it into
/// `Networking(provider:session:)` — no other change is needed to start pinning:
///
/// ```swift
/// let session = URLSession(configuration: .default, delegate: PinnedSessionDelegate(policy: policy), delegateQueue: nil)
/// let networking = Networking<HTTPClientError>(provider: server, session: session)
/// ```
@available(macOS 10.14, *)
public final class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    private let policy: PinningPolicy

    public init(policy: PinningPolicy) {
        self.policy = policy
    }

    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let isSystemTrustValid = SecTrustEvaluateWithError(trust, nil)

        guard isSystemTrustValid, policy.shouldTrust(trust, forHost: challenge.protectionSpace.host) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}
