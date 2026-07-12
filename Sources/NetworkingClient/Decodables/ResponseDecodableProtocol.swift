import Foundation

/// A strategy for decoding a response body's raw `Data` into a concrete `Decodable` type.
public protocol ResponseDecodable {
    func decode<T: Decodable>(_ data: Data) throws -> T
}
