
import Foundation
import NetwokingClient


// Enumeration representing various HTTP client errors
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
            return 4001
        case .requestFailed(let statusCode, _):
            return statusCode
        case .noData:
            return 4003
        case .decodingFailed:
            return 4004
        case .unauthorized:
            return 4010
        case .noResponse:
            return 4006
        case .generic:
            return 4005
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
    
    // Function to map status codes to corresponding HTTP client errors
    public static func map(statusCode: Int) -> HTTPClientError {
        switch statusCode {
        case 4001:
            return .invalidURL
        case 4003:
            return .noData
        case 4004:
            return .decodingFailed
        case 4006:
            return .noResponse
        case 4010:
            return .unauthorized
        default:
            return .generic
        }
    }
}
