import Foundation

// Protocol to define the structure of an endpoint
public protocol Endpoint {
    associatedtype requestType: Decodable  // The type of response expected from the endpoint
    var method: HTTPMethod { get }          // HTTP method used for the request
    var path: String { get }                // Path of the endpoint
    var body: Data? {get}                   // Optional data payload for the request
}

// Extension of the Endpoint protocol
extension Endpoint {
    // Function to convert a dictionary of parameters into a query string
    public func queryString(from parameters: [String: Any]) -> String {
        let keyValuePairs = parameters.map { key, value in
            return "\(key)=\(value)"
        }
        return keyValuePairs.joined(separator: "&")
    }
}
