import Foundation
import Security

/// Pins servers by comparing their full DER-encoded certificate against a known set.
/// Simpler to reason about than `PublicKeyPinningPolicy`, but every certificate rotation
/// on the server requires shipping an updated pin.
public struct CertificatePinningPolicy: PinningPolicy {
    private let pinnedCertificates: [String: Set<Data>]
    private let allowsUnpinnedHosts: Bool

    /// - Parameters:
    ///   - pinnedCertificates: DER-encoded certificates accepted for each host. Provide more
    ///     than one per host to support planned certificate rotation.
    ///   - allowsUnpinnedHosts: Whether hosts absent from `pinnedCertificates` fall back to
    ///     the system's default trust evaluation instead of being rejected. Defaults to `false`.
    public init(pinnedCertificates: [String: Set<Data>], allowsUnpinnedHosts: Bool = false) {
        self.pinnedCertificates = pinnedCertificates
        self.allowsUnpinnedHosts = allowsUnpinnedHosts
    }

    public func shouldTrust(_ trust: SecTrust, forHost host: String) -> Bool {
        guard let expectedCertificates = pinnedCertificates[host] else {
            return allowsUnpinnedHosts
        }

        let certificateCount = SecTrustGetCertificateCount(trust)
        for index in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, index) else { continue }
            let certificateData = SecCertificateCopyData(certificate) as Data
            if expectedCertificates.contains(certificateData) {
                return true
            }
        }
        return false
    }
}
