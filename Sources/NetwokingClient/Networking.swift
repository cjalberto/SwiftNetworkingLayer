import Foundation
import Combine

// Protocol to define network operations
public protocol Networkable {
    associatedtype ErrorType: HTTPClientErrorProtocol
    
    var provider: Server { get }       // Server provider
    var session: URLSession { get }    // URLSession for network requests
    
    // Function to make a network request with completion handler
    @available(macOS 10.15, *)
    func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, ErrorType>) -> Void)
    
    // Function to make a network request using Combine framework
    @available(iOS 13.0, macOS 13.0, *)
    func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType>
    
    // Function to make a network request using async-await
    @available(iOS 15.0, macOS 12.0, *)
    func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType>
}

// Class implementing Networkable protocol
public class Networking<ErrorType: HTTPClientErrorProtocol>: Networkable {
    public let provider: Server    // Server provider
    public let session: URLSession // URLSession for network requests
    
    // Initializer
    public init(provider: Server, session: URLSession = .shared) {
        self.provider = provider
        self.session = session
    }
    
    // Function to make a network request with completion handler
    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, ErrorType>) -> Void) {
        
        guard let request = constructRequest(for: endpoint) else {
            completion(.failure(ErrorType.map(statusCode: 400))) // Use ErrorType with a generic error or specific one
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion(.failure(ErrorType.map(statusCode: 500))) // Assuming 500 as a generic server error
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ErrorType.map(statusCode: 501))) // No response error
                return
            }

            if !(200...299 ~= httpResponse.statusCode) {
                completion(.failure(ErrorType.map(statusCode: httpResponse.statusCode))) // Use the map function from your ErrorType
                return
            }

            guard let data = data else {
                completion(.failure(ErrorType.map(statusCode: 421))) // No data error, assuming 204 as an example
                return
            }

            do {
                let decodedObject = try JSONDecoder().decode(E.requestType.self, from: data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(ErrorType.map(statusCode: 422))) // Decoding failed error, assuming 422 as an example
            }
        }.resume()
    }
    
    // Function to make a network request using Combine framework
    @available(iOS 13.0, macOS 13.0, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType> {
        guard let request = constructRequest(for: endpoint) else {
            // Return a publisher that immediately fails with your custom ErrorType
            return Fail(error: ErrorType.map(statusCode: 400)) // Invalid URL
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ErrorType.map(statusCode: 500) // Assuming 500 represents a generic server error
                }

                if !(200...299 ~= httpResponse.statusCode) {
                    throw ErrorType.map(statusCode: httpResponse.statusCode) // Use the map function from your ErrorType
                }

                return data
            }
            .decode(type: E.requestType.self, decoder: JSONDecoder())
            .mapError { error -> ErrorType in
                if let error = error as? ErrorType {
                    return error
                } else {
                    return ErrorType.map(statusCode: 422) // Example for decoding failure
                }
            }
            .eraseToAnyPublisher()
    }

    
    // Function to make a network request using async-await
    @available(iOS 15.0, macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType> {
        guard let request = constructRequest(for: endpoint) else {
            return .failure(ErrorType.map(statusCode: 400)) // Example: 400 for Bad Request
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            return .failure(ErrorType.map(statusCode: 500))
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(ErrorType.map(statusCode: 501)) // Assuming 500 represents a generic server error
        }

        if !(200...299 ~= httpResponse.statusCode) {
            // Use the injected ErrorType for HTTP status code errors
            return .failure(ErrorType.map(statusCode: httpResponse.statusCode))
        }

        do {
            let decodedObject = try JSONDecoder().decode(E.requestType.self, from: data)
            return .success(decodedObject)
        } catch {
            return .failure(ErrorType.map(statusCode: 422)) // Example: 422 for Unprocessable Entity
        }
    }
    
    // Private function to construct URLRequest
    private func constructRequest(for call: any Endpoint) -> URLRequest? {
        guard let url = URL(string: provider.baseURL + call.path)  else {
            return nil
        }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = provider.mandatoryHeaders
        request.httpMethod = call.method.rawValue
        request.httpBody = call.body
        return request
    }
}
