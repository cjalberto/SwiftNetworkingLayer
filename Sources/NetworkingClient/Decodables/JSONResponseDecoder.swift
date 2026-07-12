import Foundation

/// Decodes response bodies as JSON using `JSONDecoder`.
public struct JSONResponseDecoder: ResponseDecodable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func decode<T: Decodable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
}
