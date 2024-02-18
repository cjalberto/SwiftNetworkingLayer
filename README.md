# SwiftNetworkingLayer

SwiftNetworkingLayer is a Swift package designed to streamline networking operations in iOS applications. It provides a set of protocols, error handling mechanisms, and utility functions to simplify communication with RESTful APIs.

## Features

- **Endpoint Protocol**: Define API endpoints with HTTP methods, paths, and request body types.
- **Error Handling**: Easily handle common networking errors with the HTTPClientError enumeration.
- **HTTP Method Representation**: Use the HTTPMethod type to work with standard HTTP methods.
- **Flexible Networking**: Implement synchronous, asynchronous, and Combine-based HTTP requests with the Networkable protocol.
- **Server Configuration**: Configure server details such as base URL, environment, and mandatory headers with the Server structure and ServerFactory class.

## Installation

To integrate SwiftNetworkingLayer into your Xcode project using Swift Package Manager, add the following dependency to your `Package.swift` file:

dependencies: [
.package(url: "https://github.com/cjalberto/SwiftNetworkingLayer.git", from: "1.0.0")
]


## Usage

### Define Endpoints

```swift
struct MyEndpoint: Endpoint {
    typealias requestType = MyRequest
    var method: HTTPMethod = .get
    var path: String = "/example"
    var body: Data? = nil
}
```
### Make Requests:
```swift
let server = ServerFactory.createServer(for: "production", baseURL: "https://api.example.com")
let networking = Networking(provider: server)

networking.request(endpoint: MyEndpoint()) { result in
    switch result {
    case .success(let data):
        // Handle successful response
    case .failure(let error):
        // Handle error
    }
}
```
### Implement Error Handling
The HTTPClientError enumeration, conforming to HTTPClientErrorProtocol, illustrates an exemplary implementation of detailed error handling. It includes an errorCode property that provides specific HTTP status codes or custom codes for various error scenarios:
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
        case .invalidURL:
            return 500
        case .requestFailed(let statusCode, _):
            return statusCode
        case .noData:
            return 421
        case .decodingFailed:
            return 422
        case .unauthorized:
            return 601
        case .noResponse:
            return 501
        case .generic:
            return 400
        }
    }
    // Example mappings and descriptions omitted for brevity
}
```


This project is licensed under the MIT License - see the LICENSE file for details.

