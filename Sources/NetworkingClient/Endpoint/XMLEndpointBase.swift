import Foundation

/// An `Endpoint` that defaults to XML: it sets `Content-Type: application/xml` and
/// decodes the response body with `XMLResponseDecoder`.
public protocol XMLEndpointBase: Endpoint {
    /// Extra headers a specific endpoint can contribute. Merged over the default
    /// `Content-Type` header, taking priority on conflicts. Defaults to empty.
    var additionalHeaders: [String: String] { get }
    var decoder: XMLResponseDecoder { get }
}

extension XMLEndpointBase {
    private var defaultHeader: [String: String] {
        return ["Content-Type": "application/xml"]
    }

    public var additionalHeaders: [String: String] { [:] }

    public var headers: [String: String]? {
        defaultHeader.merging(additionalHeaders) { _, additional in additional }
    }

    public var decoder: ResponseDecodable {
        return XMLResponseDecoder()
    }
}
