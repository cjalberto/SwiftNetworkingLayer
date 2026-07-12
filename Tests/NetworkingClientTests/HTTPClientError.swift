import Foundation
import NetworkingClient

/// Reference `HTTPClientErrorProtocol` conformance used by the test suite.
public enum HTTPClientError: HTTPClientErrorProtocol {
    case invalidURL                         // The provided URL is not valid
    case requestFailed(statusCode: Int, message: String)  // The request failed with a specific status code and message
    case noData                             // No data was received in the response
    case decodingFailed                     // Error decoding the response data
    case unauthorized                       // The request requires authentication and none or invalid credentials were provided
    case noResponse                         // No response was received
    case generic                            // Unexpected error
    
    // Computed property to get the error code
    public var errorCode: Int {
        switch self {
        case .invalidURL:
            return InternalFailureCode.invalidURL.rawValue
        case .requestFailed(let statusCode, _):
            return statusCode
        case .noData:
            return InternalFailureCode.noData.rawValue
        case .decodingFailed:
            return InternalFailureCode.decodingFailed.rawValue
        case .unauthorized:
            return 401
        case .noResponse:
            return InternalFailureCode.noResponse.rawValue
        case .generic:
            return 0
        }
    }
    
    // Computed property to get the localized description of the error
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Error \(errorCode): The provided URL is not valid."
        case .requestFailed(_, let message):
            return "Error \(errorCode): The request failed. Message: \(message)"
        case .noData:
            return "Error \(errorCode): No data was received in the response."
        case .decodingFailed:
            return "Error \(errorCode): Error decoding the response data."
        case .unauthorized:
            return "Error \(errorCode): The request requires authentication and none or invalid credentials were provided."
        case .noResponse:
            return "Error \(errorCode): No response was received"
        case .generic:
            return "Error \(errorCode): Unexpected error."
        }
    }
    
    // Function to map status codes to corresponding HTTP client errors.
    // The InternalFailureCode cases (negative) are failures detected by the client before
    // receiving a response; any other code is a real HTTP status code from the server.
    public static func map(statusCode: Int) -> HTTPClientError {
        switch statusCode {
        case InternalFailureCode.invalidURL.rawValue:
            return .invalidURL
        case InternalFailureCode.noData.rawValue:
            return .noData
        case InternalFailureCode.decodingFailed.rawValue:
            return .decodingFailed
        case InternalFailureCode.noResponse.rawValue:
            return .noResponse
        case 401:
            return .unauthorized
        default:
            return .requestFailed(statusCode: statusCode, message: "HTTP error \(statusCode)")
        }
    }

    // Function to map a transport-level error (no connection, timeout, cancelled...) preserving its original info
    public static func map(underlyingError error: Error) -> HTTPClientError {
        return .requestFailed(statusCode: (error as NSError).code, message: error.localizedDescription)
    }
}
