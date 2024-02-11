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

This project is licensed under the MIT License - see the LICENSE file for details.

