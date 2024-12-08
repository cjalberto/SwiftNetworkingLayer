import Foundation

public protocol Endpoint {
    associatedtype requestType: Decodable  // Expected response type
    var method: HTTPMethod { get }         // HTTP method (GET, POST, etc.)
    var path: String { get }               // Endpoint path
    var body: Data? { get }                // Request body
    var headers: [String: String]? { get } // Custom headers for the endpoint
    var decoder: ResponseDecodable { get } // Decoding strategy for the endpoint

    /// Constructs the `URLRequest` for this endpoint
    func urlRequest(server: Server) -> URLRequest?
}

extension Endpoint {
    public func urlRequest(server: Server) -> URLRequest? {
        guard let url = URL(string: server.baseURL + path) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.allHTTPHeaderFields = headers

        return request
    }
}

extension Endpoint {
    // Function to convert a dictionary of parameters into a query string
    public func queryString(from parameters: [String: Any]) -> String {
        let keyValuePairs = parameters.map { key, value in
            return "\(key)=\(value)"
        }
        return keyValuePairs.joined(separator: "&")
    }
}
