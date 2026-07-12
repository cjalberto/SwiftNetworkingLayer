import Foundation

/// Per-request options applied to every `URLRequest` a `Networking` client builds.
///
/// Conforming types only need to override the properties they care about; every
/// property has a default via the protocol extension. Session-level options (timeouts
/// that span retries, `waitsForConnectivity`, connection limits, etc.) are configured
/// on the injected `URLSession`/`URLSessionConfiguration` instead — they are not part
/// of this protocol.
public protocol RequestConfiguration {
    var timeoutInterval: TimeInterval { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var allowsCellularAccess: Bool { get }
    var allowsExpensiveNetworkAccess: Bool { get }
    var allowsConstrainedNetworkAccess: Bool { get }
    var httpShouldHandleCookies: Bool { get }
}

extension RequestConfiguration {
    public var timeoutInterval: TimeInterval { 60 }
    public var cachePolicy: URLRequest.CachePolicy { .useProtocolCachePolicy }
    public var allowsCellularAccess: Bool { true }
    public var allowsExpensiveNetworkAccess: Bool { true }
    public var allowsConstrainedNetworkAccess: Bool { true }
    public var httpShouldHandleCookies: Bool { true }
}

/// A `RequestConfiguration` that uses `URLRequest`'s own defaults for every property.
public struct DefaultRequestConfiguration: RequestConfiguration {
    public init() {}
}
