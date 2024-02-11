import Foundation
import Combine

// Protocol to define network operations
public protocol Networkable {
    var provider: Server { get }       // Server provider
    var session: URLSession { get }    // URLSession for network requests
    
    // Function to make a network request with completion handler
    @available(macOS 10.15, *)
    func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, HTTPClientError>) -> Void)
    
    // Function to make a network request using Combine framework
    @available(iOS 13.0, macOS 13.0, *)
    func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, HTTPClientError>
    
    // Function to make a network request using async-await
    @available(iOS 15.0, macOS 12.0, *)
    func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, HTTPClientError>
}

// Class implementing Networkable protocol
public class Networking: Networkable {
    public let provider: Server    // Server provider
    public let session: URLSession // URLSession for network requests
    
    // Initializer
    public init(provider: Server, session: URLSession = .shared) {
        self.provider = provider
        self.session = session
    }
    
    // Function to make a network request with completion handler
    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, HTTPClientError>) -> Void) {
        // Construct URLRequest
        guard let request = constructRequest(for: endpoint) else {
            completion(.failure(HTTPClientError.invalidURL))
            return
        }

        // Perform data task
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(HTTPClientError.noResponse))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if !(200...299 ~= httpResponse.statusCode) {
                    completion(.failure(HTTPClientError.map(statusCode: httpResponse.statusCode)))
                    return
                }
            }

            guard let data = data else {
                completion(.failure(HTTPClientError.noData))
                return
            }

            do {
                let decodedObject = try JSONDecoder().decode(E.requestType.self, from: data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(HTTPClientError.decodingFailed))
            }
        }.resume()
    }
    
    // Function to make a network request using Combine framework
    @available(iOS 13.0, macOS 13.0, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, HTTPClientError> {
        guard let request = constructRequest(for: endpoint) else {
            return Fail(error: HTTPClientError.invalidURL)
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPClientError.generic
                }

                if !(200...299 ~= httpResponse.statusCode) {
                    throw HTTPClientError.map(statusCode: httpResponse.statusCode)
                }

                return data
            }
            .decode(type: E.requestType.self, decoder: JSONDecoder())
            .mapError { error in
                if let httpClientError = error as? HTTPClientError {
                    return httpClientError
                } else {
                    return HTTPClientError.decodingFailed
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Function to make a network request using async-await
    @available(iOS 15.0, macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, HTTPClientError> {
        guard let request = constructRequest(for: endpoint) else {
            return .failure(HTTPClientError.invalidURL)
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            return .failure(HTTPClientError.generic)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(HTTPClientError.noResponse)
        }

        if !(200...299 ~= httpResponse.statusCode) {
            return .failure(HTTPClientError.map(statusCode: httpResponse.statusCode))
        }

        do {
            let decodedObject = try JSONDecoder().decode(E.requestType.self, from: data)
            return .success(decodedObject)
        } catch {
            return .failure(HTTPClientError.decodingFailed)
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
