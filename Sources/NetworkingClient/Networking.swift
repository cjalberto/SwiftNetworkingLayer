import Foundation
import Combine

/// A type that can perform requests for any `Endpoint` — via completion handler, Combine,
/// or async/await — and report failures as `ErrorType`.
public protocol Networkable {
    associatedtype ErrorType: HTTPClientErrorProtocol

    /// The server this instance sends requests to.
    var provider: Server { get }

    /// The `URLSession` used to perform requests.
    var session: URLSession { get }

    /// The default request configuration (timeout, cache policy, etc.) applied to every
    /// request, unless a given `Endpoint` overrides it via its own `configuration`.
    var configuration: RequestConfiguration { get }

    /// Performs the request and reports the result through `completion`.
    @available(macOS 10.15, *)
    func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, ErrorType>) -> Void)

    /// Performs the request and publishes the result via Combine.
    @available(iOS 13.0, macOS 13.0, *)
    func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType>

    /// Performs the request using async/await.
    @available(iOS 15.0, macOS 12.0, *)
    func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType>
}

/// Default `Networkable` implementation, backed by `URLSession`.
public class Networking<ErrorType: HTTPClientErrorProtocol>: Networkable {
    public let provider: Server
    public let session: URLSession
    public let configuration: RequestConfiguration

    public init(provider: Server, session: URLSession = .shared, configuration: RequestConfiguration = DefaultRequestConfiguration()) {
        self.provider = provider
        self.session = session
        self.configuration = configuration
    }

    /// The endpoint's own configuration, if it defines one, otherwise this client's default.
    private func effectiveConfiguration<E: Endpoint>(for endpoint: E) -> RequestConfiguration {
        endpoint.configuration ?? self.configuration
    }

    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, ErrorType>) -> Void) {

        guard let request = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            completion(.failure(ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue)))
            return
        }

        self.session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ErrorType.map(underlyingError: error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue)))
                return
            }

            if !(200...299 ~= httpResponse.statusCode) {
                completion(.failure(ErrorType.map(statusCode: httpResponse.statusCode))) // Real HTTP error from the server
                return
            }

            guard let data = data else {
                completion(.failure(ErrorType.map(statusCode: InternalFailureCode.noData.rawValue)))
                return
            }

            do {
                let decodedObject: E.requestType = try endpoint.decoder.decode(data)
                completion(.success(decodedObject))
            } catch {
                completion(.failure(ErrorType.map(statusCode: InternalFailureCode.decodingFailed.rawValue)))
            }
        }.resume()
    }

    @available(iOS 13.0, macOS 13.0, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType> {
        guard let request = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            return Fail(error: ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue))
                .eraseToAnyPublisher()
        }

        return self.session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue)
                }

                if !(200...299 ~= httpResponse.statusCode) {
                    throw ErrorType.map(statusCode: httpResponse.statusCode) // Real HTTP error from the server
                }

                return data
            }
            .tryMap { data -> E.requestType in
                do {
                    return try endpoint.decoder.decode(data)
                } catch {
                    throw ErrorType.map(statusCode: InternalFailureCode.decodingFailed.rawValue)
                }
            }
            .mapError { error -> ErrorType in
                if let error = error as? ErrorType {
                    return error
                } else {
                    // Transport-level failure (no connection, timeout, cancelled, etc.)
                    return ErrorType.map(underlyingError: error)
                }
            }
            .eraseToAnyPublisher()
    }

    @available(iOS 15.0, macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType> {
        guard let request = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            return .failure(ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch {
            return .failure(ErrorType.map(underlyingError: error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            return .failure(ErrorType.map(statusCode: httpResponse.statusCode)) // Real HTTP error from the server
        }

        do {
            let decodedObject: E.requestType = try endpoint.decoder.decode(data)
            return .success(decodedObject)
        } catch {
            return .failure(ErrorType.map(statusCode: InternalFailureCode.decodingFailed.rawValue))
        }
    }
}
