import Foundation
import Security

/// Decides whether a server's TLS trust should be accepted for a given host.
///
/// Conforming types are injected into a `PinnedSessionDelegate`, which combines this
/// decision with the system's own certificate-chain validation: a connection is only
/// trusted if both agree.
public protocol PinningPolicy {
    func shouldTrust(_ trust: SecTrust, forHost host: String) -> Bool
}
