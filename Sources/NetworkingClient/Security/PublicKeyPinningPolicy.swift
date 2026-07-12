import Foundation
import Security
import CommonCrypto

/// Pins servers by the SHA-256 hash of their certificate's public key, which survives
/// certificate renewal as long as the underlying key pair doesn't change — unlike
/// `CertificatePinningPolicy`, which breaks on every renewal.
///
/// The hash is computed over the raw public key bytes returned by
/// `SecKeyCopyExternalRepresentation` (not the full ASN.1 SubjectPublicKeyInfo some
/// external tools use), so generate pins with `PublicKeyPinningPolicy.pin(forCertificateData:)`
/// rather than a generic `openssl` one-liner.
@available(macOS 10.14, *)
public struct PublicKeyPinningPolicy: PinningPolicy {
    private let pinnedHashes: [String: Set<String>]
    private let allowsUnpinnedHosts: Bool

    /// - Parameters:
    ///   - pinnedHashes: Base64-encoded public-key hashes accepted for each host. Provide
    ///     more than one per host to support planned key rotation (e.g. a backup pin).
    ///   - allowsUnpinnedHosts: Whether hosts absent from `pinnedHashes` fall back to the
    ///     system's default trust evaluation instead of being rejected. Defaults to `false`.
    public init(pinnedHashes: [String: Set<String>], allowsUnpinnedHosts: Bool = false) {
        self.pinnedHashes = pinnedHashes
        self.allowsUnpinnedHosts = allowsUnpinnedHosts
    }

    public func shouldTrust(_ trust: SecTrust, forHost host: String) -> Bool {
        guard let expectedHashes = pinnedHashes[host] else {
            return allowsUnpinnedHosts
        }

        let certificateCount = SecTrustGetCertificateCount(trust)
        for index in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(trust, index),
                  let hash = Self.publicKeyHash(for: certificate) else {
                continue
            }
            if expectedHashes.contains(hash) {
                return true
            }
        }
        return false
    }

    /// Computes the pin value for a DER-encoded certificate, using the same hashing this
    /// policy uses internally. Use this to generate the values passed into `pinnedHashes`.
    public static func pin(forCertificateData certificateData: Data) -> String? {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            return nil
        }
        return publicKeyHash(for: certificate)
    }

    private static func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return Data(digest).base64EncodedString()
    }
}
