
import Foundation

public protocol HTTPClientErrorProtocol: Error {
    var localizedDescription: String { get }
    var errorCode: Int { get }
    static func map(statusCode: Int) -> Self
}
