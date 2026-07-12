import XCTest
import Security
@testable import NetworkingClient

final class SecurityTests: XCTestCase {

    // MARK: - Fixtures
    //
    // Self-signed test certificates (DER, base64), generated once with:
    //   openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes -subj "/CN=<host>"
    //   openssl x509 -in cert.pem -outform der -out cert.der

    private static let pinnedHost = "pinning-test.example.com"

    private static let pinnedCertificateBase64 = "MIIDJzCCAg+gAwIBAgIURhNkZrhZFvC3KCq8SpMNsChpf7gwDQYJKoZIhvcNAQELBQAwIzEhMB8GA1UEAwwYcGlubmluZy10ZXN0LmV4YW1wbGUuY29tMB4XDTI2MDcxMjAzMDczMloXDTM2MDcwOTAzMDczMlowIzEhMB8GA1UEAwwYcGlubmluZy10ZXN0LmV4YW1wbGUuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5ELVJVglUycCULB2Rb3lHFTV/C3qwOYhVBq0TLCBCDlU0i0jMiPKDEYJAThASSiLoPj5JMtkIcspO3eZFZRVbNqazNavp/wNAf9dGV7ihZjudutFcR6XOLm/TDBzmy90J/XSdKZOBn/HqGzisDr51rrADFNppSnyHH5NOeTIaaaVz0S7MC3ZlVtlemU4+qklpbUvWOwyQtDnFke0MDezuKTeRhgChMGbhSX3fe4GzTPUO7V4+daElnWfPBiYduG8Y8K6kpioFBSBFmOIGsTwSPTddacXyL3h5yAXFgT2TH5gnYdj1ugTRI4S5iMTBh7Ptitz01DNuRy//Svq3mikrwIDAQABo1MwUTAdBgNVHQ4EFgQUblIoFy40ERTQWxwYFiwQr947jyswHwYDVR0jBBgwFoAUblIoFy40ERTQWxwYFiwQr947jyswDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEArzsAR3zn9Bh2YZmNBbCkI8/Dq/80tSIwb4ME+khkwON59UNniBfGwzYKEg1PwRCe9Q27TppNsPsbROApilcjWdz+848fPhiW5Bm4zEmuckzPKteHT3c7K1fo53HrteafEXC4tOoyucSCgErIGT6/+gTe9WiTXXJotIA+x9wzLdOoUm3WM/SIQBwdK5IgNdcZqrVU1X4GgIIw4R5j5bMCguDf1wY97cNh3SjTZHpJXwaSlw8nDn7fkM1zowuGSvMt4n+r+CT3ii0H6JJ7GxXNu6ARAdk7i0VXjtKtJ7mw7JRUO87auNYjc8RJ6ieBUuiybbpnWtnaUFbV+sev80GuNQ=="

    private static let otherCertificateBase64 = "MIIDGTCCAgGgAwIBAgIUYtPjBStoSoRHZ63/ISZ9SwaCppAwDQYJKoZIhvcNAQELBQAwHDEaMBgGA1UEAwwRb3RoZXIuZXhhbXBsZS5jb20wHhcNMjYwNzEyMDMwNzMyWhcNMzYwNzA5MDMwNzMyWjAcMRowGAYDVQQDDBFvdGhlci5leGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANn/hXctqjTsGZdIBZ5qK3KjSbML3EJjKBVYpMtp5d5YR2rvTs0QmXR5lT8n5o+33fmXtflcIDrhdSBBWNoZT4ZWtzPLL2al0citRmOV/rzLME7Y7ms6UePzD6dP6Vp1bKj5IwM0PuuRua0eW2wvSyFKbl4Y+DPMm2omKpM/SKHSJUfYlXm10O+gdASG+WVuSsGMnoQxQNLPcjMPXOgPHnFL9QnBOIEIiW+LC1NveNaJ8opsonAgIWTEku3adG8f2/5rE5b+xlz/JM7vswcAJk6rpjIfZEYvTvQTgWCK9aRym1BgomnXQX4ARMwE7XiZyQ7Cz+7X4tQo86G7SnDXc3MCAwEAAaNTMFEwHQYDVR0OBBYEFCW12TBFoHCpK1gRQs3LFPaa6K7dMB8GA1UdIwQYMBaAFCW12TBFoHCpK1gRQs3LFPaa6K7dMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAJYf4P0W2EHQ669yA3CjLA1wbojLQeptBO0DetX2VOdUREqOw8fOsh7K01uCaeLnqalqF/GRk/eF5wp07dkxvYfdvbRElAJzU0wyUVzvmrM53PhU3YOuob/rjZdTZEkQxxpoFA5TIzuVwf+ttmk78dpzISdpI25CBLCaaorVzocYvCYIxOWMiom4M9HrTt02bWBh8N/Yzz7uO5QJKAj6/vKqEWIkOWno5WS2jQmPD8b7BndsIwfppN3AKLqm7qxj3q+28XVEJZ3pDwXFWFkWqq5wiKKyhI+XlTiBXkrtG7b54C9YqZHVOw1/Iu3R2VNQwHkpqlhNGT8R2mbKzX3PJ8c="

    private var pinnedCertificateData: Data { Data(base64Encoded: Self.pinnedCertificateBase64)! }
    private var otherCertificateData: Data { Data(base64Encoded: Self.otherCertificateBase64)! }

    private func certificate(from data: Data) -> SecCertificate {
        SecCertificateCreateWithData(nil, data as CFData)!
    }

    private func trust(for certificate: SecCertificate) -> SecTrust {
        var trust: SecTrust?
        SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        return trust!
    }

    // MARK: - PublicKeyPinningPolicy

    @available(macOS 10.14, *)
    func testPublicKeyPinningPolicyTrustsThePinnedHost() {
        let pin = PublicKeyPinningPolicy.pin(forCertificateData: pinnedCertificateData)!
        let policy = PublicKeyPinningPolicy(pinnedHashes: [Self.pinnedHost: [pin]])

        XCTAssertTrue(policy.shouldTrust(trust(for: certificate(from: pinnedCertificateData)), forHost: Self.pinnedHost))
    }

    @available(macOS 10.14, *)
    func testPublicKeyPinningPolicyRejectsAWrongCertificateForAPinnedHost() {
        let pin = PublicKeyPinningPolicy.pin(forCertificateData: pinnedCertificateData)!
        let policy = PublicKeyPinningPolicy(pinnedHashes: [Self.pinnedHost: [pin]])

        XCTAssertFalse(policy.shouldTrust(trust(for: certificate(from: otherCertificateData)), forHost: Self.pinnedHost))
    }

    @available(macOS 10.14, *)
    func testPublicKeyPinningPolicyRejectsUnpinnedHostsByDefault() {
        let pin = PublicKeyPinningPolicy.pin(forCertificateData: pinnedCertificateData)!
        let policy = PublicKeyPinningPolicy(pinnedHashes: [Self.pinnedHost: [pin]])

        XCTAssertFalse(policy.shouldTrust(trust(for: certificate(from: pinnedCertificateData)), forHost: "unlisted.example.com"))
    }

    @available(macOS 10.14, *)
    func testPublicKeyPinningPolicyAllowsUnpinnedHostsWhenOptedIn() {
        let policy = PublicKeyPinningPolicy(pinnedHashes: [:], allowsUnpinnedHosts: true)

        XCTAssertTrue(policy.shouldTrust(trust(for: certificate(from: otherCertificateData)), forHost: "unlisted.example.com"))
    }

    @available(macOS 10.14, *)
    func testPublicKeyPinComputationIsStableAndDistinguishesCertificates() {
        let pinA = PublicKeyPinningPolicy.pin(forCertificateData: pinnedCertificateData)
        let pinAAgain = PublicKeyPinningPolicy.pin(forCertificateData: pinnedCertificateData)
        let pinB = PublicKeyPinningPolicy.pin(forCertificateData: otherCertificateData)

        XCTAssertNotNil(pinA)
        XCTAssertEqual(pinA, pinAAgain)
        XCTAssertNotEqual(pinA, pinB)
    }

    // MARK: - CertificatePinningPolicy

    func testCertificatePinningPolicyTrustsThePinnedHost() {
        let policy = CertificatePinningPolicy(pinnedCertificates: [Self.pinnedHost: [pinnedCertificateData]])

        XCTAssertTrue(policy.shouldTrust(trust(for: certificate(from: pinnedCertificateData)), forHost: Self.pinnedHost))
    }

    func testCertificatePinningPolicyRejectsAWrongCertificateForAPinnedHost() {
        let policy = CertificatePinningPolicy(pinnedCertificates: [Self.pinnedHost: [pinnedCertificateData]])

        XCTAssertFalse(policy.shouldTrust(trust(for: certificate(from: otherCertificateData)), forHost: Self.pinnedHost))
    }

    func testCertificatePinningPolicyRejectsUnpinnedHostsByDefault() {
        let policy = CertificatePinningPolicy(pinnedCertificates: [Self.pinnedHost: [pinnedCertificateData]])

        XCTAssertFalse(policy.shouldTrust(trust(for: certificate(from: pinnedCertificateData)), forHost: "unlisted.example.com"))
    }

    func testCertificatePinningPolicyAllowsUnpinnedHostsWhenOptedIn() {
        let policy = CertificatePinningPolicy(pinnedCertificates: [:], allowsUnpinnedHosts: true)

        XCTAssertTrue(policy.shouldTrust(trust(for: certificate(from: otherCertificateData)), forHost: "unlisted.example.com"))
    }

    // MARK: - ServerFactory HTTPS guard
    //
    // Rejecting a plain http:// baseURL without allowsInsecureHTTP triggers a `precondition`
    // failure (a fatal trap) by design, so that path can't be safely exercised in-process here.

    func testCreateServerAcceptsHTTPSByDefault() {
        _ = ServerFactory.createServer(for: "", baseURL: "https://example.com") // Not crashing is the assertion.
    }

    func testCreateServerAcceptsHTTPWhenExplicitlyAllowed() {
        _ = ServerFactory.createServer(for: "", baseURL: "http://localhost:3000", allowsInsecureHTTP: true) // Not crashing is the assertion.
    }
}
