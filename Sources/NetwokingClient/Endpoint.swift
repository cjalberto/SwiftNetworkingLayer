import Foundation


public protocol Endpoint {
    associatedtype requestType: Decodable
    var method: HTTPMethod { get }
    var path: String { get }
    var body: Data? {get}
}

extension Endpoint {
    public func queryString(from parameters: [String: Any]) -> String {
        let keyValuePairs = parameters.map { key, value in
            return "\(key)=\(value)"
        }
        return keyValuePairs.joined(separator: "&")
    }
}
