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

    /// Supplies and refreshes the bearer token attached to every request. `nil` (the
    /// default) sends no `Authorization` header and never retries on 401.
    public let authTokenProvider: AuthTokenProvider?

    /// Observes every request this instance sends. `nil` (the default) means no logging
    /// happens at all.
    public let logger: NetworkLogger?

    public init(
        provider: Server,
        session: URLSession = .shared,
        configuration: RequestConfiguration = DefaultRequestConfiguration(),
        authTokenProvider: AuthTokenProvider? = nil,
        logger: NetworkLogger? = nil
    ) {
        self.provider = provider
        self.session = session
        self.configuration = configuration
        self.authTokenProvider = authTokenProvider
        self.logger = logger
    }

    /// The endpoint's own configuration, if it defines one, otherwise this client's default.
    private func effectiveConfiguration<E: Endpoint>(for endpoint: E) -> RequestConfiguration {
        endpoint.configuration ?? self.configuration
    }

    // MARK: - Completion handler

    @available(macOS 10.15, *)
    public func request<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.requestType, ErrorType>) -> Void) {
        guard let baseRequest = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            let error = ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue)
            logger?.log(.didFail(request: nil, error: error, duration: 0))
            completion(.failure(error))
            return
        }

        attachTokenIfNeeded(to: baseRequest) { request in
            self.performRequest(request, endpoint: endpoint, allowsRetry: true, completion: completion)
        }
    }

    @available(macOS 10.15, *)
    private func attachTokenIfNeeded(to request: URLRequest, completion: @escaping (URLRequest) -> Void) {
        guard let authTokenProvider = authTokenProvider else {
            completion(request)
            return
        }
        authTokenProvider.currentToken { token in
            var request = request
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            completion(request)
        }
    }

    @available(macOS 10.15, *)
    private func performRequest<E: Endpoint>(
        _ request: URLRequest,
        endpoint: E,
        allowsRetry: Bool,
        completion: @escaping (Result<E.requestType, ErrorType>) -> Void
    ) {
        let startTime = Date()
        logger?.log(.willSend(request))

        self.session.dataTask(with: request) { data, response, error in
            let duration = Date().timeIntervalSince(startTime)

            if let error = error {
                self.logger?.log(.didFail(request: request, error: error, duration: duration))
                completion(.failure(ErrorType.map(underlyingError: error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                let mappedError = ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue)
                self.logger?.log(.didFail(request: request, error: mappedError, duration: duration))
                completion(.failure(mappedError))
                return
            }

            self.logger?.log(.didReceive(request: request, response: httpResponse, data: data ?? Data(), duration: duration))

            if httpResponse.statusCode == 401, allowsRetry, let authTokenProvider = self.authTokenProvider {
                authTokenProvider.refreshToken { newToken in
                    guard let newToken = newToken else {
                        completion(.failure(ErrorType.map(statusCode: httpResponse.statusCode)))
                        return
                    }
                    var retriedRequest = request
                    retriedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    self.performRequest(retriedRequest, endpoint: endpoint, allowsRetry: false, completion: completion)
                }
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

    // MARK: - Combine

    @available(iOS 13.0, macOS 13.0, *)
    public func request<E: Endpoint>(endpoint: E) -> AnyPublisher<E.requestType, ErrorType> {
        guard let baseRequest = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            let error = ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue)
            logger?.log(.didFail(request: nil, error: error, duration: 0))
            return Fail(error: error).eraseToAnyPublisher()
        }

        return attachTokenIfNeededPublisher(to: baseRequest)
            .setFailureType(to: Error.self)
            .flatMap { request in
                self.performRequestPublisher(request, allowsRetry: true)
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

    @available(iOS 13.0, macOS 10.15, *)
    private func attachTokenIfNeededPublisher(to request: URLRequest) -> AnyPublisher<URLRequest, Never> {
        guard let authTokenProvider = authTokenProvider else {
            return Just(request).eraseToAnyPublisher()
        }
        return Future<URLRequest, Never> { promise in
            authTokenProvider.currentToken { token in
                var request = request
                if let token = token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                promise(.success(request))
            }
        }
        .eraseToAnyPublisher()
    }

    @available(iOS 13.0, macOS 10.15, *)
    private func performRequestPublisher(_ request: URLRequest, allowsRetry: Bool) -> AnyPublisher<Data, Error> {
        let startTime = Date()
        logger?.log(.willSend(request))

        return session.dataTaskPublisher(for: request)
            .mapError { error -> Error in
                self.logger?.log(.didFail(request: request, error: error, duration: Date().timeIntervalSince(startTime)))
                return error
            }
            .flatMap { data, response -> AnyPublisher<Data, Error> in
                let duration = Date().timeIntervalSince(startTime)

                guard let httpResponse = response as? HTTPURLResponse else {
                    let mappedError = ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue)
                    self.logger?.log(.didFail(request: request, error: mappedError, duration: duration))
                    return Fail(error: mappedError).eraseToAnyPublisher()
                }

                self.logger?.log(.didReceive(request: request, response: httpResponse, data: data, duration: duration))

                if httpResponse.statusCode == 401, allowsRetry, let authTokenProvider = self.authTokenProvider {
                    return Future<URLRequest, Error> { promise in
                        authTokenProvider.refreshToken { newToken in
                            guard let newToken = newToken else {
                                promise(.failure(ErrorType.map(statusCode: httpResponse.statusCode)))
                                return
                            }
                            var retriedRequest = request
                            retriedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                            promise(.success(retriedRequest))
                        }
                    }
                    .flatMap { retriedRequest in
                        self.performRequestPublisher(retriedRequest, allowsRetry: false)
                    }
                    .eraseToAnyPublisher()
                }

                guard 200...299 ~= httpResponse.statusCode else {
                    return Fail(error: ErrorType.map(statusCode: httpResponse.statusCode)).eraseToAnyPublisher() // Real HTTP error from the server
                }

                return Just(data).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Async/await

    @available(iOS 15.0, macOS 12.0, *)
    public func request<E: Endpoint>(endpoint: E) async -> Result<E.requestType, ErrorType> {
        guard let baseRequest = endpoint.urlRequest(server: self.provider, configuration: effectiveConfiguration(for: endpoint)) else {
            let error = ErrorType.map(statusCode: InternalFailureCode.invalidURL.rawValue)
            logger?.log(.didFail(request: nil, error: error, duration: 0))
            return .failure(error)
        }

        let request = await attachTokenIfNeeded(to: baseRequest)
        return await performRequestAsync(request, endpoint: endpoint, allowsRetry: true)
    }

    @available(iOS 15.0, macOS 12.0, *)
    private func attachTokenIfNeeded(to request: URLRequest) async -> URLRequest {
        guard let authTokenProvider = authTokenProvider else { return request }

        let token = await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            authTokenProvider.currentToken { continuation.resume(returning: $0) }
        }

        var request = request
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    @available(iOS 15.0, macOS 12.0, *)
    private func performRequestAsync<E: Endpoint>(_ request: URLRequest, endpoint: E, allowsRetry: Bool) async -> Result<E.requestType, ErrorType> {
        let startTime = Date()
        logger?.log(.willSend(request))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch {
            logger?.log(.didFail(request: request, error: error, duration: Date().timeIntervalSince(startTime)))
            return .failure(ErrorType.map(underlyingError: error))
        }

        let duration = Date().timeIntervalSince(startTime)

        guard let httpResponse = response as? HTTPURLResponse else {
            let mappedError = ErrorType.map(statusCode: InternalFailureCode.noResponse.rawValue)
            logger?.log(.didFail(request: request, error: mappedError, duration: duration))
            return .failure(mappedError)
        }

        logger?.log(.didReceive(request: request, response: httpResponse, data: data, duration: duration))

        if httpResponse.statusCode == 401, allowsRetry, let authTokenProvider = self.authTokenProvider {
            let newToken = await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
                authTokenProvider.refreshToken { continuation.resume(returning: $0) }
            }
            guard let newToken = newToken else {
                return .failure(ErrorType.map(statusCode: httpResponse.statusCode))
            }
            var retriedRequest = request
            retriedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return await performRequestAsync(retriedRequest, endpoint: endpoint, allowsRetry: false)
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
