import Foundation

/// An `Endpoint` that defaults to JSON: it sets `Content-Type: application/json` and
/// decodes the response body with `JSONResponseDecoder`.
public protocol JSONEndpointBase: Endpoint {
    /// Extra headers a specific endpoint can contribute. Merged over the default
    /// `Content-Type` header, taking priority on conflicts. Defaults to empty.
    var additionalHeaders: [String: String] { get }
    var decoder: ResponseDecodable { get }
}

extension JSONEndpointBase {
    private var defaultHeader: [String: String] {
        return ["Content-Type": "application/json"]
    }

    public var additionalHeaders: [String: String] { [:] }

    public var headers: [String: String]? {
        defaultHeader.merging(additionalHeaders) { _, additional in additional }
    }

    public var decoder: ResponseDecodable {
        return JSONResponseDecoder()
    }
}
