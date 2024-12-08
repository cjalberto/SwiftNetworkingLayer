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
        
        guard let request = endpoint.urlRequest(server: self.provider) else {
            completion(.failure(ErrorType.map(statusCode: 400))) // Invalid URL
            return
        }
        
        self.session.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion(.failure(ErrorType.map(statusCode: 500))) // Generic server error
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ErrorType.map(statusCode: 501))) // No response error
                return
            }

            if !(200...299 ~= httpResponse.statusCode) {
                completion(.failure(ErrorType.map(statusCode: httpResponse.statusCode))) // HTTP error
                return
            }

            guard let data = data else {
                completion(.failure(ErrorType.map(statusCode: 421))) // No data error
                return
            }
            
            do {
                let decodedObject: E.requestType = try endpoint.decoder.decode(data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(ErrorType.map(statusCode: 422))) // Decoding failed error
            }
        }.resume()
    }
    
    // Function to make a network request using Combine framework
    @available(iOS 13.0, macOS 13.0, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType> {
        guard let request = endpoint.urlRequest(server: self.provider) else {
            return Fail(error: ErrorType.map(statusCode: 400)) // Invalid URL
                .eraseToAnyPublisher()
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ErrorType.map(statusCode: 500) // Generic server error
                }

                if !(200...299 ~= httpResponse.statusCode) {
                    throw ErrorType.map(statusCode: httpResponse.statusCode) // HTTP error
                }

                return data
            }
            .tryMap { data in
                let decodedObject: E.requestType = try endpoint.decoder.decode(data)
                return decodedObject
            }
            .mapError { error -> ErrorType in
                if let error = error as? ErrorType {
                    return error
                } else {
                    return ErrorType.map(statusCode: 422) // Decoding failure
                }
            }
            .eraseToAnyPublisher()
    }

    // Function to make a network request using async-await
    @available(iOS 15.0, macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType> {
        guard let request = endpoint.urlRequest(server: self.provider) else {
            return .failure(ErrorType.map(statusCode: 400)) // Invalid URL
        }
        
        do {
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return .failure(ErrorType.map(statusCode: 500)) // HTTP error
            }
            
            let decodedObject: E.requestType = try endpoint.decoder.decode(data)
            return .success(decodedObject)
        } catch {
            return .failure(ErrorType.map(statusCode: 422)) // Decoding failure
        }
    }
}
