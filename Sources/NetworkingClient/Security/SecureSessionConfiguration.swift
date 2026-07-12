import Foundation
import Network

/// Builds `URLSessionConfiguration`s with security-conscious defaults.
public enum SecureSessionConfiguration {
    /// A `.default` configuration that rejects connections below `minimumTLSVersion`.
    ///
    /// ```swift
    /// let session = URLSession(configuration: SecureSessionConfiguration.make(minimumTLSVersion: .TLSv12))
    /// let networking = Networking<HTTPClientError>(provider: server, session: session)
    /// ```
    @available(iOS 13.0, macOS 10.15, *)
    public static func make(minimumTLSVersion: tls_protocol_version_t = .TLSv12) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = minimumTLSVersion
        return configuration
    }
}
