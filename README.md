# SwiftNetworkingLayer

SwiftNetworkingLayer is a Swift package designed to streamline networking operations in iOS applications. It provides a set of protocols, error handling mechanisms, and utility functions to simplify communication with RESTful APIs.

## Features

- **Endpoint Protocol**: Define API endpoints with HTTP methods, paths, and request body types.
- **Error Handling**: Easily handle common networking errors with the HTTPClientError enumeration.
- **HTTP Method Representation**: Use the HTTPMethod type to work with standard HTTP methods.
- **Flexible Networking**: Implement synchronous, asynchronous, and Combine-based HTTP requests with the Networkable protocol.
- **Server Configuration**: Configure server details such as base URL, environment, and mandatory headers with the Server structure and ServerFactory class.
- **Injectable Request Configuration**: Customize per-request options (timeout, cache policy, etc.) by injecting your own `RequestConfiguration`, at the client level or per endpoint.
- **Security**: Certificate/public-key pinning (`PinningPolicy`), a guard against accidentally using plaintext HTTP, a TLS-minimum-version helper, and an injectable `AuthTokenProvider` for bearer tokens with automatic refresh-and-retry on 401.
- **Injectable Logging**: Observe every request/response through a `NetworkLogger`, off by default; `ConsoleNetworkLogger` is a reference implementation that redacts sensitive headers.

## Installation

To integrate SwiftNetworkingLayer into your Xcode project using Swift Package Manager, add the following dependency to your `Package.swift` file:

dependencies: [
.package(url: "https://github.com/cjalberto/SwiftNetworkingLayer.git", from: "1.0.0")
]


## Usage

### Define a Server

```swift
import NetworkingClient

let server = ServerFactory.createServer(
    for: "production",
    baseURL: "https://api.example.com",
    apiKey: "your-api-key" // sent as the "api-key" header on every request
)
```

### Define Endpoints

`JSONEndpointBase` (or `XMLEndpointBase`) gives you the `Content-Type` and `decoder` for free, so you only need to define the method, path, and body:

```swift
struct MyRequest: Decodable { /* ... */ }

struct MyEndpoint: JSONEndpointBase {
    typealias requestType = MyRequest
    var method: HTTPMethod = .get
    var path: String = "example"
    var body: Data? = nil
}
```

### Make Requests

`Networking` supports closures, Combine, and async/await using the same endpoint definition:

```swift
let networking = Networking<HTTPClientError>(provider: server)

// Closure
networking.request(endpoint: MyEndpoint()) { result in
    switch result {
    case .success(let response):
        // Handle successful response
        break
    case .failure(let error):
        // Handle error
        break
    }
}

// async/await
let result = await networking.request(endpoint: MyEndpoint())

// Combine
let cancellable = networking.request(endpoint: MyEndpoint())
    .sink(receiveCompletion: { _ in }, receiveValue: { response in })
```

### Configure Requests

Per-request options (timeout, cache policy, cellular/expensive/constrained network access, cookie handling) are defined by the `RequestConfiguration` protocol. Every property has a default, so you only override what you need:

```swift
struct SlowUploadConfiguration: RequestConfiguration {
    var timeoutInterval: TimeInterval { 120 }
}
```

Inject it at the client level to apply it to every request made through that `Networking` instance:

```swift
let networking = Networking<HTTPClientError>(provider: server, configuration: SlowUploadConfiguration())
```

Or override it for a single endpoint, which takes priority over the client's configuration:

```swift
struct UploadEndpoint: JSONEndpointBase {
    typealias requestType = UploadResponse
    var method: HTTPMethod = .post
    var path: String = "upload"
    var body: Data?
    var configuration: RequestConfiguration? { SlowUploadConfiguration() }
}
```

Session-level options that outlive a single request — `timeoutIntervalForResource`, `waitsForConnectivity`, `httpMaximumConnectionsPerHost`, TLS/certificate handling, etc. — aren't part of `RequestConfiguration`. Configure them on a `URLSessionConfiguration` and inject the resulting `URLSession` instead: `Networking(provider: server, session: URLSession(configuration: yourConfiguration))`.

### Security

`ServerFactory.createServer` requires `https://` by default — it traps with a clear message if `baseURL` uses plain `http://`, so a mistake in a `mandatoryHeaders`/`apiKey` setup can't accidentally ship sending secrets unencrypted. Pass `allowsInsecureHTTP: true` for local development against `http://localhost`:

```swift
let server = ServerFactory.createServer(for: "", baseURL: "http://localhost:3000", allowsInsecureHTTP: true)
```

#### Certificate / public-key pinning

`PinningPolicy` decides whether to trust a server's TLS certificate for a given host. Two implementations are provided — pick a `PublicKeyPinningPolicy` if you want pins to survive certificate renewal (recommended), or a `CertificatePinningPolicy` if you'd rather pin the exact certificate:

```swift
// Generate the pin once from your server's certificate:
let pin = PublicKeyPinningPolicy.pin(forCertificateData: certificateDERData)!

let policy = PublicKeyPinningPolicy(pinnedHashes: ["api.example.com": [pin]])
let session = URLSession(configuration: .default, delegate: PinnedSessionDelegate(policy: policy), delegateQueue: nil)
let networking = Networking<HTTPClientError>(provider: server, session: session)
```

No changes to `Networking` are needed — pinning plugs in through the same `session` injection point used for any other `URLSession` customization. A connection is only trusted when **both** the system's own certificate-chain validation and your `PinningPolicy` agree.

#### Minimum TLS version

```swift
let session = URLSession(configuration: SecureSessionConfiguration.make(minimumTLSVersion: .TLSv12))
let networking = Networking<HTTPClientError>(provider: server, session: session)
```

#### Bearer tokens with automatic refresh

Implement `AuthTokenProvider` to attach `Authorization: Bearer <token>` to every request and refresh it automatically the first time a request comes back `401 Unauthorized` (retried exactly once):

```swift
final class MyAuthTokenProvider: AuthTokenProvider {
    func currentToken(completion: @escaping (String?) -> Void) {
        completion(KeychainTokenStore.shared.accessToken)
    }

    func refreshToken(completion: @escaping (String?) -> Void) {
        // Call your refresh endpoint, store the new token, then hand it back.
        AuthService.refresh { newToken in completion(newToken) }
    }
}

let networking = Networking<HTTPClientError>(provider: server, authTokenProvider: MyAuthTokenProvider())
```

### Logging

`Networking` reports every request's lifecycle (`willSend`, `didReceive`, `didFail`) to an injected `NetworkLogger`. It's `nil` by default — no logging happens, and enabling it never happens by accident:

```swift
let networking = Networking<HTTPClientError>(provider: server, logger: ConsoleNetworkLogger())
```

`ConsoleNetworkLogger` redacts sensitive headers before printing — by default `Authorization`, `api-key`, `Cookie`, and `Set-Cookie` (add your own, e.g. a custom session header, via its initializer) — and only prints body sizes, not content, unless you opt into `bodyLoggingPolicy: .always` for local debugging:

```swift
let logger = ConsoleNetworkLogger(
    redactedHeaders: ["Authorization", "api-key", "X-Session-Token"],
    bodyLoggingPolicy: .always // Prints request/response bodies as text — local debugging only.
)
```

Implement `NetworkLogger` yourself to send events to `os.Logger`, Crashlytics breadcrumbs, or anywhere else — you receive the raw `URLRequest`/`Data`, so redact anything sensitive the same way `ConsoleNetworkLogger` does before writing it anywhere persistent.

### Implement Error Handling

`HTTPClientError` (conforming to `HTTPClientErrorProtocol`) is a reference implementation. `map(statusCode:)` receives either a **real** HTTP status code returned by the server, or one of the `InternalFailureCode` values (negative codes defined by the library) for failures the client detects before getting a response — they never collide, because the two ranges never overlap. `map(underlyingError:)` preserves the real transport error (no connection, timeout, cancelled...).

```swift
public enum HTTPClientError: HTTPClientErrorProtocol {
    case invalidURL
    case requestFailed(statusCode: Int, message: String)
    case noData
    case decodingFailed
    case unauthorized
    case noResponse
    case generic

    public var errorCode: Int {
        switch self {
        case .invalidURL: return InternalFailureCode.invalidURL.rawValue
        case .requestFailed(let statusCode, _): return statusCode
        case .noData: return InternalFailureCode.noData.rawValue
        case .decodingFailed: return InternalFailureCode.decodingFailed.rawValue
        case .unauthorized: return 401
        case .noResponse: return InternalFailureCode.noResponse.rawValue
        case .generic: return 0
        }
    }

    public static func map(statusCode: Int) -> HTTPClientError {
        switch statusCode {
        case InternalFailureCode.invalidURL.rawValue: return .invalidURL
        case InternalFailureCode.noData.rawValue: return .noData
        case InternalFailureCode.decodingFailed.rawValue: return .decodingFailed
        case InternalFailureCode.noResponse.rawValue: return .noResponse
        case 401: return .unauthorized
        default: return .requestFailed(statusCode: statusCode, message: "HTTP error \(statusCode)")
        }
    }

    public static func map(underlyingError error: Error) -> HTTPClientError {
        return .requestFailed(statusCode: (error as NSError).code, message: error.localizedDescription)
    }
    // Example descriptions omitted for brevity
}
```


This project is licensed under the MIT License - see the LICENSE file for details.

